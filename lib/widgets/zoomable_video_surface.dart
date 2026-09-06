import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Wraps a [VideoPlayerController]'s video output in a two-finger
/// pinch-to-zoom + pan surface, preserving the video's aspect ratio.
///
/// Zoom range: 1.0x (default) up to [maxScale]. Double-tap toggles
/// between 1.0x and 2.0x, centered on the tap location.
class ZoomableVideoSurface extends StatefulWidget {
  const ZoomableVideoSurface({
    super.key,
    required this.controller,
    this.maxScale = 4.0,
    this.onScaleChanged,
  });

  final VideoPlayerController controller;
  final double maxScale;
  final ValueChanged<double>? onScaleChanged;

  @override
  State<ZoomableVideoSurface> createState() => ZoomableVideoSurfaceState();
}

class ZoomableVideoSurfaceState extends State<ZoomableVideoSurface>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController = TransformationController();
  late final AnimationController _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  Animation<Matrix4>? _resetAnimation;

  double get currentScale => _transformController.value.getMaxScaleOnAxis();

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_handleTransformChange);
  }

  void _handleTransformChange() {
    widget.onScaleChanged?.call(currentScale);
  }

  @override
  void dispose() {
    _transformController.removeListener(_handleTransformChange);
    _transformController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void resetZoom() {
    _animateTo(Matrix4.identity());
  }

  void _animateTo(Matrix4 target) {
    _resetAnimation = Matrix4Tween(
      begin: _transformController.value,
      end: target,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _animController
      ..reset()
      ..addListener(_onResetTick)
      ..forward().whenComplete(() {
        _animController.removeListener(_onResetTick);
      });
  }

  void _onResetTick() {
    if (_resetAnimation != null) {
      _transformController.value = _resetAnimation!.value;
    }
  }

  void _handleDoubleTapDown(TapDownDetails details, Size viewportSize) {
    final isZoomed = currentScale > 1.01;
    if (isZoomed) {
      resetZoom();
      return;
    }

    const targetScale = 2.0;
    final tapPos = details.localPosition;
    final x = -tapPos.dx * (targetScale - 1);
    final y = -tapPos.dy * (targetScale - 1);

    final target = Matrix4.identity()
      ..translate(x, y)
      ..scale(targetScale);

    _animateTo(target);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onDoubleTapDown: (details) => _handleDoubleTapDown(details, viewportSize),
          onDoubleTap: () {},
          child: InteractiveViewer(
            transformationController: _transformController,
            minScale: 1.0,
            maxScale: widget.maxScale,
            panEnabled: true,
            scaleEnabled: true,
            trackpadScrollCausesScale: false,
            child: Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.isInitialized
                    ? widget.controller.value.aspectRatio
                    : 16 / 9,
                child: VideoPlayer(widget.controller),
              ),
            ),
          ),
        );
      },
    );
  }
}
