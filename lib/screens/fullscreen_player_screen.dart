import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../models/download_item.dart';
import '../widgets/player_controls_overlay.dart';
import '../widgets/zoomable_video_surface.dart';

class FullscreenPlayerScreen extends StatefulWidget {
  const FullscreenPlayerScreen({
    super.key,
    required this.controller,
    required this.item,
    required this.onDownload,
  });

  final VideoPlayerController controller;
  final DownloadItem item;
  final VoidCallback onDownload;

  @override
  State<FullscreenPlayerScreen> createState() => _FullscreenPlayerScreenState();
}

class _FullscreenPlayerScreenState extends State<FullscreenPlayerScreen> {
  final GlobalKey<ZoomableVideoSurfaceState> _zoomKey = GlobalKey();
  bool _controlsVisible = true;
  bool _locked = false;
  double _speed = 1.0;
  double _zoom = 1.0;
  Timer? _hideTimer;

  static const _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    widget.controller.play();
    _scheduleAutoHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _scheduleAutoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !_locked) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleAutoHide();
  }

  void _toggleLock() {
    setState(() {
      _locked = !_locked;
      _controlsVisible = true;
    });
    if (!_locked) _scheduleAutoHide();
  }

  void _seekBy(int seconds) {
    final current = widget.controller.value.position;
    final target = current + Duration(seconds: seconds);
    final duration = widget.controller.value.duration;
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > duration ? duration : target);
    widget.controller.seekTo(clamped);
    _scheduleAutoHide();
  }

  void _cycleSpeed() {
    final index = _speeds.indexOf(_speed);
    final next = _speeds[(index + 1) % _speeds.length];
    setState(() => _speed = next);
    widget.controller.setPlaybackSpeed(next);
    _scheduleAutoHide();
  }

  void _resetZoom() {
    _zoomKey.currentState?.resetZoom();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _locked ? _toggleControls : _toggleControls,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: ZoomableVideoSurface(
                  key: _zoomKey,
                  controller: widget.controller,
                  onScaleChanged: (scale) => setState(() => _zoom = scale),
                ),
              ),
              if (widget.controller.value.isBuffering)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              PlayerControlsOverlay(
                controller: widget.controller,
                visible: _controlsVisible,
                locked: _locked,
                onToggleVisible: _toggleControls,
                onToggleLock: _toggleLock,
                onClose: () => Navigator.of(context).pop(),
                onDownload: widget.onDownload,
                onSeekBy: _seekBy,
                onSpeedTap: _cycleSpeed,
                onResetZoom: _resetZoom,
                playbackSpeed: _speed,
                currentZoom: _zoom,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
