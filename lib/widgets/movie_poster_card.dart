import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/movie_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A single poster card used in horizontal content rows. Uses a subtle
/// scale-down on press (rather than a shadow or border color change) as
/// the primary press-feedback signal, matching the "no drop shadows on
/// true black" philosophy.
class MoviePosterCard extends StatefulWidget {
  const MoviePosterCard({
    super.key,
    required this.movie,
    required this.onTap,
    this.width = 130,
    this.showProgress,
  });

  final Movie movie;
  final VoidCallback onTap;
  final double width;

  /// 0.0-1.0 continue-watching progress; when non-null a thin progress
  /// bar is drawn along the bottom edge of the poster.
  final double? showProgress;

  @override
  State<MoviePosterCard> createState() => _MoviePosterCardState();
}

class _MoviePosterCardState extends State<MoviePosterCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final height = widget.width * 1.5;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: AppMotion.micro,
        curve: AppMotion.standard,
        child: SizedBox(
          width: widget.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Hero(
                      tag: 'movie-backdrop-${widget.movie.id}',
                      child: SizedBox(
                        width: widget.width,
                        height: height,
                        child: widget.movie.posterUrl != null
                            ? CachedNetworkImage(
                                imageUrl: widget.movie.posterUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppColors.bgSurfaceElevated,
                                ),
                                errorWidget: (context, url, error) => _PosterFallback(
                                  title: widget.movie.title,
                                ),
                              )
                            : _PosterFallback(title: widget.movie.title),
                      ),
                    ),
                  ),
                  if (widget.showProgress != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(AppSpacing.radiusSm),
                          bottomRight: Radius.circular(AppSpacing.radiusSm),
                        ),
                        child: Container(
                          height: 3,
                          color: Colors.black45,
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: widget.showProgress!.clamp(0.0, 1.0),
                            child: Container(color: AppColors.accentBrand),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSurfaceElevated,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Text(
        title,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTypography.bodySm,
      ),
    );
  }
}
