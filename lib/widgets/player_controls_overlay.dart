import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../utils/format_utils.dart';

class PlayerControlsOverlay extends StatelessWidget {
  const PlayerControlsOverlay({
    super.key,
    required this.controller,
    required this.visible,
    required this.locked,
    required this.onToggleVisible,
    required this.onToggleLock,
    required this.onClose,
    required this.onDownload,
    required this.onSeekBy,
    required this.onSpeedTap,
    required this.onResetZoom,
    required this.playbackSpeed,
    required this.currentZoom,
  });

  final VideoPlayerController controller;
  final bool visible;
  final bool locked;
  final VoidCallback onToggleVisible;
  final VoidCallback onToggleLock;
  final VoidCallback onClose;
  final VoidCallback onDownload;
  final void Function(int seconds) onSeekBy;
  final VoidCallback onSpeedTap;
  final VoidCallback onResetZoom;
  final double playbackSpeed;
  final double currentZoom;

  @override
  Widget build(BuildContext context) {
    if (locked) {
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: visible ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !visible,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _RoundButton(icon: Icons.lock_outline_rounded, onTap: onToggleLock),
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: visible ? 1.0 : 0.0,
      child: IgnorePointer(
        ignoring: !visible,
        child: Container(
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
                _TopBar(onClose: onClose, onDownload: onDownload),
                const Spacer(),
                if (currentZoom > 1.05)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextButton.icon(
                      onPressed: onResetZoom,
                      icon: const Icon(Icons.zoom_out_map_rounded, color: Colors.white),
                      label: Text(
                        '${currentZoom.toStringAsFixed(1)}x • Reset',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundButton(
                      icon: Icons.replay_10_rounded,
                      onTap: () => onSeekBy(-10),
                      large: true,
                    ),
                    const SizedBox(width: 28),
                    _PlayPauseButton(controller: controller),
                    const SizedBox(width: 28),
                    _RoundButton(
                      icon: Icons.forward_10_rounded,
                      onTap: () => onSeekBy(10),
                      large: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _BottomBar(
                  controller: controller,
                  onToggleLock: onToggleLock,
                  onSpeedTap: onSpeedTap,
                  playbackSpeed: playbackSpeed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose, required this.onDownload});
  final VoidCallback onClose;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: onClose,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: onDownload,
          ),
        ],
      ),
    );
  }
}

class _PlayPauseButton extends StatefulWidget {
  const _PlayPauseButton({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<_PlayPauseButton> {
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
    return _RoundButton(
      icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
      large: true,
      size: 56,
      onTap: () {
        isPlaying ? widget.controller.pause() : widget.controller.play();
      },
    );
  }
}

class _BottomBar extends StatefulWidget {
  const _BottomBar({
    required this.controller,
    required this.onToggleLock,
    required this.onSpeedTap,
    required this.playbackSpeed,
  });

  final VideoPlayerController controller;
  final VoidCallback onToggleLock;
  final VoidCallback onSpeedTap;
  final double playbackSpeed;

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: duration.inMilliseconds > 0
                  ? position.inMilliseconds
                      .clamp(0, duration.inMilliseconds)
                      .toDouble()
                  : 0.0,
              max: duration.inMilliseconds > 0
                  ? duration.inMilliseconds.toDouble()
                  : 1.0,
              activeColor: Colors.white,
              inactiveColor: Colors.white24,
              onChanged: (v) {
                widget.controller.seekTo(Duration(milliseconds: v.round()));
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                FormatUtils.formatDuration(position),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: widget.onSpeedTap,
                    child: Text(
                      '${widget.playbackSpeed}x',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.lock_open_rounded, color: Colors.white, size: 20),
                    onPressed: widget.onToggleLock,
                  ),
                ],
              ),
              Text(
                FormatUtils.formatDuration(duration),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.onTap,
    this.large = false,
    this.size,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool large;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black38,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(large ? 14 : 10),
          child: Icon(icon, color: Colors.white, size: size ?? (large ? 32 : 22)),
        ),
      ),
    );
  }
}
