import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/movie_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The Home screen's hero banner: a 16:9-ish backdrop with a bottom
/// scrim gradient, title, metadata badges, and Play/My List CTAs.
///
/// Gradient: transparent through 40% of the height, then ramping to 80%
/// black by 85%, reaching solid black at 100% — this keeps the top of
/// the backdrop image clean (so it reads as "cinematic still") while
/// guaranteeing text legibility over the busiest part of most images
/// (the lower-middle, where subjects are usually framed).
class HeroBanner extends StatelessWidget {
  const HeroBanner({
    super.key,
    required this.movie,
    required this.onPlay,
    required this.onMoreInfo,
  });

  final Movie movie;
  final VoidCallback onPlay;
  final VoidCallback onMoreInfo;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2 / 3, // Tall enough on mobile to show title + CTAs
      // comfortably below the fold of a typical phone's status bar.
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (movie.backdropUrl != null)
            CachedNetworkImage(
              imageUrl: movie.backdropUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: AppColors.bgSurface),
              errorWidget: (context, url, error) => Container(color: AppColors.bgSurface),
            )
          else
            Container(color: AppColors.bgSurface),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.heroScrimColors,
                stops: AppColors.heroScrimStops,
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            bottom: AppSpacing.xxxl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movie.title,
                  style: AppTypography.headlineLg,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.sm),
                _MetadataBadgeRow(movie: movie),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onPlay,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Play'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _GlassButton(
                        icon: Icons.info_outline_rounded,
                        label: 'More Info',
                        onTap: onMoreInfo,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Metadata bar: rating, year, duration, and quality badges with exact
/// 8px gaps between each element (space-sm token).
class _MetadataBadgeRow extends StatelessWidget {
  const _MetadataBadgeRow({required this.movie});
  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 16, color: AppColors.accentGold),
            const SizedBox(width: AppSpacing.xxs),
            Text(movie.ratingLabel, style: AppTypography.labelSm),
          ],
        ),
        if (movie.releaseYear != null)
          Text('${movie.releaseYear}', style: AppTypography.labelSm),
        if (movie.runtimeLabel.isNotEmpty)
          Text(movie.runtimeLabel, style: AppTypography.labelSm),
        const _QualityBadge(label: 'HD'),
      ],
    );
  }
}

class _QualityBadge extends StatelessWidget {
  const _QualityBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderStrong),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm / 2),
      ),
      child: Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
    );
  }
}

/// A glassmorphism-style secondary CTA: translucent fill + hairline
/// border, standing in for a frosted-glass button over busy backdrop
/// imagery (chosen over solid fill so the backdrop stays partially
/// visible through the button, reinforcing the "glass over image" feel).
class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: AppColors.borderDefault),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: AppTypography.labelLg),
            ],
          ),
        ),
      ),
    );
  }
}
