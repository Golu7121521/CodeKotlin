import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/download_item.dart';
import '../utils/format_utils.dart';

class MiniPreviewCard extends StatefulWidget {
  const MiniPreviewCard({
    super.key,
    required this.item,
    required this.controller,
    required this.onDownload,
    required this.onFullscreen,
    required this.onClose,
  });

  final DownloadItem item;
  final VideoPlayerController? controller;
  final VoidCallback onDownload;
  final VoidCallback onFullscreen;
  final VoidCallback onClose;

  @override
  State<MiniPreviewCard> createState() => _MiniPreviewCardState();
}

class _MiniPreviewCardState extends State<MiniPreviewCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  late final Animation<double> _scale = Tween<double>(begin: 0.92, end: 1.0)
      .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = widget.controller;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: (controller != null && controller.value.isInitialized)
                          ? controller.value.aspectRatio
                          : 16 / 9,
                      child: controller != null && controller.value.isInitialized
                          ? VideoPlayer(controller)
                          : Container(
                              color: scheme.surfaceContainerHighest,
                              child: const Center(
                                child: SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(strokeWidth: 2.4),
                                ),
                              ),
                            ),
                    ),
                    if (controller != null && controller.value.isInitialized)
                      _PlayPauseOverlay(controller: controller),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: _RoundIconButton(
                        icon: Icons.close_rounded,
                        onTap: widget.onClose,
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: _RoundIconButton(
                        icon: Icons.fullscreen_rounded,
                        onTap: widget.onFullscreen,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title?.isNotEmpty == true
                            ? widget.item.title!
                            : widget.item.filename,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (widget.item.durationMs != null)
                            FormatUtils.formatDuration(
                              Duration(milliseconds: widget.item.durationMs!),
                            ),
                          if (widget.item.fileSizeBytes != null)
                            FormatUtils.formatBytes(widget.item.fileSizeBytes),
                        ].join(' • '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: widget.onDownload,
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Download'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayPauseOverlay extends StatefulWidget {
  const _PlayPauseOverlay({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_PlayPauseOverlay> createState() => _PlayPauseOverlayState();
}

class _PlayPauseOverlayState extends State<_PlayPauseOverlay> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.controller.value.isPlaying;
    return GestureDetector(
      onTap: () {
        isPlaying ? widget.controller.pause() : widget.controller.play();
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isPlaying ? 0.0 : 1.0,
        child: Container(
          color: Colors.black26,
          child: const Center(
            child: Icon(Icons.play_arrow_rounded, size: 56, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
