import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_typography.dart';

/// The Cinematic Video Player's control surface. Layer order (bottom to
/// top, matching the required Z-index hierarchy):
///   1. Video layer          - the VideoPlayer widget itself (painted by caller)
///   2. Subtitle layer        - reserved via [subtitleBuilder], sits above video
///   3. UI controls layer     - play/pause, scrubber, top/bottom bars
///   4. Gesture overlay layer - invisible full-surface tap/double-tap catcher,
///      topmost so it always receives touches first, then explicitly
///      forwards single taps to toggle the controls layer beneath it.
class CinematicPlayerControls extends StatefulWidget {
  const CinematicPlayerControls({
    super.key,
    required this.controller,
    required this.onClose,
    this.subtitleBuilder,
    this.onSeekFeedback,
  });

  final VideoPlayerController controller;
  final VoidCallback onClose;
  final WidgetBuilder? subtitleBuilder;
  final void Function(int seconds)? onSeekFeedback;

  @override
  State<CinematicPlayerControls> createState() => _CinematicPlayerControlsState();
}

class _CinematicPlayerControlsState extends State<CinematicPlayerControls> {
  bool _controlsVisible = true;
  Timer? _hideTimer;

  // Double-tap seek feedback state: which side was tapped and how many
  // consecutive taps (so rapid double-taps accumulate, e.g. tap-tap-tap
  // = +30s not just +10s three separate times) before the feedback fades.
  _SeekFeedback? _seekFeedback;
  Timer? _seekFeedbackTimer;

  @override
  void initState() {
    super.initState();
    _scheduleAutoHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekFeedbackTimer?.cancel();
    super.dispose();
  }

  void _scheduleAutoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleAutoHide();
  }

  void _handleDoubleTap(bool isForward) {
    final current = widget.controller.value.position;
    final target = current + Duration(seconds: isForward ? 10 : -10);
    widget.controller.seekTo(target < Duration.zero ? Duration.zero : target);
    widget.onSeekFeedback?.call(isForward ? 10 : -10);

    setState(() {
      if (_seekFeedback != null && _seekFeedback!.isForward == isForward) {
        _seekFeedback = _SeekFeedback(
          isForward: isForward,
          totalSeconds: _seekFeedback!.totalSeconds + 10,
        );
      } else {
        _seekFeedback = _SeekFeedback(isForward: isForward, totalSeconds: 10);
      }
    });

    _seekFeedbackTimer?.cancel();
    _seekFeedbackTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _seekFeedback = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Layer 2: subtitles, sit directly above the video, below controls.
        if (widget.subtitleBuilder != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Builder(builder: widget.subtitleBuilder!),
          ),

        // Layer 3: UI controls (fades in/out).
        AnimatedOpacity(
          duration: AppMotion.small,
          opacity: _controlsVisible ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: !_controlsVisible,
            child: _ControlsChrome(
              controller: widget.controller,
              onClose: widget.onClose,
            ),
          ),
        ),

        // Layer 4: gesture overlay, topmost, always hit-testable.
        Positioned.fill(
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleControls,
                  onDoubleTap: () => _handleDoubleTap(false),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleControls,
                  onDoubleTap: () => _handleDoubleTap(true),
                ),
              ),
            ],
          ),
        ),

        // Seek feedback ripple + spring-animated +/-10s text, drawn above
        // the gesture layer so it's never occluded.
        if (_seekFeedback != null)
          Align(
            alignment:
                _seekFeedback!.isForward ? Alignment.centerRight : Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: _SeekFeedbackBubble(feedback: _seekFeedback!),
            ),
          ),
      ],
    );
  }
}

class _SeekFeedback {
  final bool isForward;
  final int totalSeconds;
  const _SeekFeedback({required this.isForward, required this.totalSeconds});
}

class _SeekFeedbackBubble extends StatefulWidget {
  const _SeekFeedbackBubble({required this.feedback});
  final _SeekFeedback feedback;

  @override
  State<_SeekFeedbackBubble> createState() => _SeekFeedbackBubbleState();
}

class _SeekFeedbackBubbleState extends State<_SeekFeedbackBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.small,
  )..forward();

  late final Animation<double> _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: AppMotion.spring),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.feedback.isForward
        ? Icons.fast_forward_rounded
        : Icons.fast_rewind_rounded;

    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 2),
            Text(
              '${widget.feedback.totalSeconds}s',
              style: AppTypography.labelSm.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlsChrome extends StatefulWidget {
  const _ControlsChrome({required this.controller, required this.onClose});
  final VideoPlayerController controller;
  final VoidCallback onClose;

  @override
  State<_ControlsChrome> createState() => _ControlsChromeState();
}

class _ControlsChromeState extends State<_ControlsChrome> {
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
    final value = widget.controller.value;
    final position = value.position;
    final duration = value.duration;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.transparent, Colors.black87],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            const Spacer(),
            IconButton(
              iconSize: 56,
              icon: Icon(
                value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: Colors.white,
              ),
              onPressed: () {
                value.isPlaying ? widget.controller.pause() : widget.controller.play();
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: AppColors.accentBrand,
                      thumbColor: AppColors.accentBrand,
                      inactiveTrackColor: Colors.white24,
                    ),
                    child: Slider(
                      value: duration.inMilliseconds > 0
                          ? position.inMilliseconds
                              .clamp(0, duration.inMilliseconds)
                              .toDouble()
                          : 0.0,
                      max: duration.inMilliseconds > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                      onChanged: (v) => widget.controller.seekTo(Duration(milliseconds: v.round())),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position),
                          style: AppTypography.caption.copyWith(color: Colors.white)),
                      Text(_formatDuration(duration),
                          style: AppTypography.caption.copyWith(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
