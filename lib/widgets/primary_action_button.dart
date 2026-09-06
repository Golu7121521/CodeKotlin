import 'package:flutter/material.dart';

class PrimaryActionButton extends StatefulWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  State<PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<PrimaryActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    lowerBound: 0.0,
    upperBound: 0.04,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.isLoading;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1 - _controller.value;
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => _controller.forward(),
        onTapUp: disabled ? null : (_) => _controller.reverse(),
        onTapCancel: disabled ? null : () => _controller.reverse(),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: disabled ? null : widget.onPressed,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: widget.isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    )
                  : Row(
                      key: const ValueKey('label'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: 20),
                          const SizedBox(width: 10),
                        ],
                        Text(widget.label),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
