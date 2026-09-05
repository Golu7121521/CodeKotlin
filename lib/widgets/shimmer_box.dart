import 'package:flutter/material.dart';

import '../providers/performance_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';

/// A shimmering skeleton placeholder, used for the Discovery Engine's
/// "Loading State". In [AppPerformanceMode.reduced] the animated sweep is
/// replaced with a static, slightly-lighter-than-base rectangle — no
/// animation at all — since a moving gradient is one of the more
/// GPU-costly effects to keep running on a low-end device's home screen.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
    this.performanceMode = AppPerformanceMode.full,
  });

  final double width;
  final double height;
  final double borderRadius;
  final AppPerformanceMode performanceMode;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.ambient,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);

    if (widget.performanceMode == AppPerformanceMode.reduced) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.bgSurfaceElevated,
          borderRadius: radius,
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              final sweep = _controller.value;
              return LinearGradient(
                begin: Alignment(-1 + sweep * 3, 0),
                end: Alignment(0 + sweep * 3, 0),
                colors: const [
                  AppColors.bgSurfaceElevated,
                  AppColors.bgSurfaceElevatedHigh,
                  AppColors.bgSurfaceElevated,
                ],
                stops: const [0.35, 0.5, 0.65],
              ).createShader(bounds);
            },
            child: Container(
              width: widget.width,
              height: widget.height,
              color: AppColors.bgSurfaceElevated,
            ),
          );
        },
      ),
    );
  }
}

/// A full skeleton row matching the poster-card layout, used while
/// [CatalogLoadState.loading] is active for a given content row.
class ShimmerPosterRow extends StatelessWidget {
  const ShimmerPosterRow({
    super.key,
    this.itemCount = 6,
    this.performanceMode = AppPerformanceMode.full,
  });

  final int itemCount;
  final AppPerformanceMode performanceMode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => ShimmerBox(
          width: 130,
          height: 195,
          performanceMode: performanceMode,
        ),
      ),
    );
  }
}
