import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../controllers/video_flow_controller.dart';
import '../models/download_item.dart';
import '../providers/downloads_provider.dart';
import '../services/share_intent_service.dart';
import '../widgets/download_progress_card.dart';
import '../widgets/mini_preview_card.dart';
import '../widgets/primary_action_button.dart';
import '../widgets/url_input_field.dart';
import 'downloads_screen.dart';
import 'fullscreen_player_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _urlController = TextEditingController();
  late final VideoFlowController _flowController;
  VideoPlayerController? _previewPlayerController;
  int _navIndex = 0;
  final _shareIntentService = ShareIntentService();

  bool _previewInitFailed = false;

  @override
  void initState() {
    super.initState();
    final downloadsProvider = context.read<DownloadsProvider>();
    _flowController = VideoFlowController(downloadsProvider: downloadsProvider);
    _flowController.addListener(_onFlowChanged);
    // Rebuild whenever the URL text changes so the "Preview & Download"
    // button's enabled state (and clear/paste icons) always reflect the
    // current field contents. Without this listener the button could
    // stay stuck in whatever enabled/disabled state it had at the last
    // rebuild, since typing into the field alone doesn't rebuild
    // HomeScreen.
    _urlController.addListener(_onUrlTextChanged);
    _shareIntentService.initialize(
      onUrlReceived: (url) {
        if (!mounted) return;
        _urlController.text = url;
      },
    );
  }

  void _onUrlTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _flowController.removeListener(_onFlowChanged);
    _urlController.removeListener(_onUrlTextChanged);
    _flowController.dispose();
    _urlController.dispose();
    _previewPlayerController?.dispose();
    _shareIntentService.dispose();
    super.dispose();
  }

  String? _playerInitializedForPath;

  void _onFlowChanged() {
    if (_flowController.state == FlowState.previewReady &&
        _flowController.tempFilePath != null &&
        _playerInitializedForPath != _flowController.tempFilePath) {
      // Guard with _playerInitializedForPath so a preview for the same
      // temp file isn't re-initialized on every notifyListeners() call
      // (e.g. from unrelated progress updates), which previously caused
      // the player to be torn down and rebuilt repeatedly.
      _playerInitializedForPath = _flowController.tempFilePath;
      _initPreviewPlayer(_flowController.tempFilePath!);
    }
    if (mounted) setState(() {});
  }

  Future<void> _initPreviewPlayer(String path) async {
    await _previewPlayerController?.dispose();
    _previewPlayerController = null;
    if (mounted) setState(() => _previewInitFailed = false);

    final file = File(path);
    if (!await file.exists() || await file.length() == 0) {
      if (mounted) setState(() => _previewInitFailed = true);
      return;
    }

    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _previewPlayerController = controller;
      setState(() {});
    } catch (_) {
      // The downloaded file exists but the player couldn't decode it
      // (e.g. an unsupported/partial file). Surface this instead of
      // silently leaving a blank preview card.
      await controller.dispose();
      if (mounted) setState(() => _previewInitFailed = true);
    }
  }

  void _submit() {
    final text = _urlController.text.trim();
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    _flowController.processUrl(text);
  }

  Future<void> _onDownloadPressed() async {
    final item = await _flowController.confirmDownload();
    if (!mounted) return;
    if (item != null) {
      _showSuccessSnackbar(item);
    } else if (_flowController.errorMessage != null) {
      _showErrorSnackbar(_flowController.errorMessage!);
    }
  }

  void _showSuccessSnackbar(DownloadItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('Saved "${item.filename}"')),
          ],
        ),
        action: SnackBarAction(
          label: 'Share',
          onPressed: () {
            if (item.localPath != null) {
              SharePlus.instance.share(ShareParams(files: [XFile(item.localPath!)]));
            }
          },
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _closePreview() {
    _flowController.discardPreview();
    _previewPlayerController?.dispose();
    _previewPlayerController = null;
    _playerInitializedForPath = null;
    _previewInitFailed = false;
    _urlController.clear();
    setState(() {});
  }

  void _openFullscreen() {
    if (_previewPlayerController == null || _flowController.currentItem == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenPlayerScreen(
          controller: _previewPlayerController!,
          item: _flowController.currentItem!,
          onDownload: _onDownloadPressed,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeBody(context),
      const DownloadsScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _navIndex == 0 ? _buildAppBar(context) : null,
      body: IndexedStack(index: _navIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.download_outlined), selectedIcon: Icon(Icons.download_rounded), label: 'Downloads'),
          NavigationDestination(icon: Icon(Icons.history_rounded), selectedIcon: Icon(Icons.history_rounded), label: 'History'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.tertiary,
                ],
              ),
            ),
            child: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text('All Video Downloader', style: TextStyle(fontSize: 17)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => setState(() => _navIndex = 3),
        ),
      ],
    );
  }

  Widget _buildHomeBody(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return SingleChildScrollView(
      // Keeping physics consistent (rather than letting content-size
      // jumps fight the default bouncing scroll physics) avoids the
      // jittery/odd feel reported when the status area changes height.
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UrlInputField(
            controller: _urlController,
            onSubmit: _submit,
            enabled: !_flowController.isBusy,
          ),
          const SizedBox(height: 16),
          PrimaryActionButton(
            label: 'Preview & Download',
            icon: Icons.play_arrow_rounded,
            isLoading: _flowController.isBusy,
            onPressed: _urlController.text.trim().isEmpty ? null : _submit,
          ),
          const SizedBox(height: 24),
          // AnimatedSize smooths out the height change as the status
          // area swaps between nothing / progress card / preview card /
          // error card, instead of the layout snapping instantly, which
          // is what produced the jerky scroll feeling.
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildStatusArea(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusArea(BuildContext context) {
    switch (_flowController.state) {
      case FlowState.idle:
        return const SizedBox.shrink(key: ValueKey('idle'));
      case FlowState.validating:
      case FlowState.callingApi:
      case FlowState.fetchingPreview:
        return DownloadProgressCard(
          key: const ValueKey('progress'),
          statusText: _flowController.statusMessage,
          progress: _flowController.previewProgress,
        );
      case FlowState.previewReady:
        if (_flowController.currentItem == null) return const SizedBox.shrink();
        if (_previewInitFailed) {
          return _ErrorCard(
            key: const ValueKey('preview-failed'),
            message: 'Video preview could not be loaded.',
            onDismiss: _closePreview,
          );
        }
        return MiniPreviewCard(
          key: const ValueKey('preview'),
          item: _flowController.currentItem!,
          controller: _previewPlayerController,
          onDownload: _onDownloadPressed,
          onFullscreen: _openFullscreen,
          onClose: _closePreview,
        );
      case FlowState.error:
        return _ErrorCard(
          key: const ValueKey('error'),
          message: _flowController.errorMessage ?? 'Something went wrong.',
          onDismiss: _closePreview,
        );
    }
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({super.key, required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: scheme.onErrorContainer)),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

