import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../models/movie_model.dart';
import '../../models/stream_source_model.dart';
import '../../services/storage_service.dart';
import '../../services/stream_resolver.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/cinematic_player_controls.dart';

enum _PlayerLoadState { resolving, ready, error }

/// The Cinematic Video Player screen. Resolves [movie] to a playable
/// source via [StreamResolver] (never scraping or sniffing — see that
/// class's docs), then hands the resulting URL to Flutter's native
/// video_player/Chewie pipeline for hardware-accelerated playback.
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key, required this.movie});

  final Movie movie;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  final _resolver = StreamResolver();
  final _storage = StorageService();

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  _PlayerLoadState _state = _PlayerLoadState.resolving;
  ResolvedStream? _resolvedStream;
  StreamSource? _currentSource;
  String? _errorMessage;
  bool _pausedByAudioFocusLoss = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WakelockPlus.enable();
    _loadStream();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveProgress();
    _chewieController?.dispose();
    _videoController?.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  /// Edge case: sudden audio focus loss (e.g. an incoming phone call).
  /// AppLifecycleState.inactive/paused fires in this scenario on
  /// Android/iOS; we pause playback and let the "Pause & Dim" overlay
  /// (a simple black scrim + pause icon, reusing the controls chrome)
  /// remain visible so the user immediately understands why playback
  /// stopped, rather than resuming to a jarring silent-then-loud cut back
  /// in when they return.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (controller.value.isPlaying) {
        _pausedByAudioFocusLoss = true;
        controller.pause();
        setState(() {});
      }
    } else if (state == AppLifecycleState.resumed && _pausedByAudioFocusLoss) {
      _pausedByAudioFocusLoss = false;
      // Deliberately leave playback paused on resume rather than
      // auto-resuming — resuming audio/video without explicit user
      // action after a phone call is a common source of startled users.
      setState(() {});
    }
  }

  Future<void> _saveProgress() async {
    final controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    await _storage.savePlaybackPosition(
      widget.movie.id,
      controller.value.position,
      controller.value.duration,
    );
  }

  Future<void> _loadStream() async {
    setState(() => _state = _PlayerLoadState.resolving);

    final resolved = await _resolver.resolve(widget.movie.id);
    if (!mounted) return;

    if (!resolved.hasSources) {
      setState(() {
        _state = _PlayerLoadState.error;
        _errorMessage = "This title isn't available to stream right now.";
      });
      return;
    }

    _resolvedStream = resolved;
    await _initializePlayback(resolved.preferred ?? resolved.sources.first);
  }

  Future<void> _initializePlayback(StreamSource source) async {
    setState(() => _state = _PlayerLoadState.resolving);

    await _chewieController?.dispose();
    await _videoController?.dispose();

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(source.url),
        httpHeaders: source.headers ?? const {},
      );
      await controller.initialize().timeout(const Duration(seconds: 15));

      final resumePosition = await _storage.getPlaybackPosition(widget.movie.id);
      if (resumePosition != null && resumePosition.position > Duration.zero) {
        await controller.seekTo(resumePosition.position);
      }

      if (!mounted) return;

      _videoController = controller;
      _chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        showControls: false, // We render our own CinematicPlayerControls.
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.accentBrand,
        ),
      );
      _currentSource = source;
      setState(() => _state = _PlayerLoadState.ready);
    } catch (_) {
      if (!mounted) return;
      await _tryNextSourceOrFail(source);
    }
  }

  /// Fallback logic: if the current source fails/times out, automatically
  /// try the next configured source (multi-server fallback) before
  /// surfacing an error with a manual server switcher.
  Future<void> _tryNextSourceOrFail(StreamSource failedSource) async {
    final sources = _resolvedStream?.sources ?? const [];
    final currentIndex = sources.indexOf(failedSource);
    final nextIndex = currentIndex + 1;

    if (nextIndex < sources.length) {
      await _initializePlayback(sources[nextIndex]);
      return;
    }

    setState(() {
      _state = _PlayerLoadState.error;
      _errorMessage = 'Playback failed on all available servers.';
    });
  }

  void _switchServer(StreamSource source) {
    if (source == _currentSource) return;
    _initializePlayback(source);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          top: false,
          bottom: false,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _PlayerLoadState.resolving:
        return const _ResolvingState();
      case _PlayerLoadState.error:
        return _PlayerErrorState(
          message: _errorMessage ?? 'Playback failed.',
          onClose: () => Navigator.of(context).pop(),
        );
      case _PlayerLoadState.ready:
        final chewie = _chewieController;
        final video = _videoController;
        if (chewie == null || video == null) return const _ResolvingState();
        return Stack(
          fit: StackFit.expand,
          children: [
            Chewie(controller: chewie),
            CinematicPlayerControls(
              controller: video,
              onClose: () => Navigator.of(context).pop(),
            ),
            if (_pausedByAudioFocusLoss) const _AudioFocusLossOverlay(),
            if ((_resolvedStream?.sources.length ?? 0) > 1)
              Positioned(
                top: 8,
                right: 8,
                child: _ServerSwitcher(
                  sources: _resolvedStream!.sources,
                  current: _currentSource,
                  onSelect: _switchServer,
                ),
              ),
          ],
        );
    }
  }
}

class _ResolvingState extends StatelessWidget {
  const _ResolvingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: AppColors.accentBrand),
          SizedBox(height: 16),
          Text('Loading stream...', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _PlayerErrorState extends StatelessWidget {
  const _PlayerErrorState({required this.message, required this.onClose});
  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLg.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onClose, child: const Text('Go Back')),
          ],
        ),
      ),
    );
  }
}

/// "Pause & Dim" overlay shown when audio focus is lost (e.g. an
/// incoming call): a soft black scrim plus a centered pause icon,
/// deliberately understated so it reads as "paused for you", not as an
/// error state.
class _AudioFocusLossOverlay extends StatelessWidget {
  const _AudioFocusLossOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Icon(Icons.pause_circle_outline_rounded, color: Colors.white70, size: 56),
      ),
    );
  }
}

class _ServerSwitcher extends StatelessWidget {
  const _ServerSwitcher({
    required this.sources,
    required this.current,
    required this.onSelect,
  });

  final List<StreamSource> sources;
  final StreamSource? current;
  final void Function(StreamSource) onSelect;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<StreamSource>(
      icon: const Icon(Icons.dns_rounded, color: Colors.white),
      onSelected: onSelect,
      itemBuilder: (context) => sources
          .map((s) => PopupMenuItem(
                value: s,
                child: Row(
                  children: [
                    if (s == current)
                      const Icon(Icons.check_rounded, size: 18, color: AppColors.accentBrand)
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Text('${s.label}${s.quality != null ? ' (${s.quality})' : ''}'),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
