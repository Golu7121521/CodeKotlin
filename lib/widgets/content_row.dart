import 'package:flutter/material.dart';

import '../models/movie_model.dart';
import '../providers/performance_provider.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'movie_poster_card.dart';
import 'shimmer_box.dart';

/// A titled horizontal row of movie posters. As the user scrolls, cards
/// approaching the row's edges scale down slightly and fade, giving a
/// subtle parallax/depth feel — the currently-centered-ish card(s) stay
/// at full scale/opacity. This effect is skipped entirely in
/// [AppPerformanceMode.reduced] (cards render at fixed scale/opacity),
/// since per-frame scroll-position listening is exactly the kind of
/// continuous work that's costly on low-end devices.
class ContentRow extends StatefulWidget {
  const ContentRow({
    super.key,
    required this.title,
    required this.movies,
    required this.onMovieTap,
    this.isLoading = false,
    this.progressForMovie,
    this.performanceMode = AppPerformanceMode.full,
  });

  final String title;
  final List<Movie> movies;
  final void Function(Movie movie) onMovieTap;
  final bool isLoading;
  final double? Function(int movieId)? progressForMovie;
  final AppPerformanceMode performanceMode;

  @override
  State<ContentRow> createState() => _ContentRowState();
}

class _ContentRowState extends State<ContentRow> {
  final ScrollController _scrollController = ScrollController();

  static const double _cardWidth = 130;
  static const double _cardSpacing = 12;
  static const double _rowPadding = 20;

  @override
  void initState() {
    super.initState();
    if (widget.performanceMode == AppPerformanceMode.full) {
      _scrollController.addListener(_updateParallax);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateParallax);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateParallax() {
    // Relies on ScrollController's own frame-synced notification cadence
    // rather than a separate throttling timer.
    setState(() {});
  }

  double _scaleForIndex(int index, double viewportWidth) {
    if (widget.performanceMode == AppPerformanceMode.reduced ||
        !_scrollController.hasClients) {
      return 1.0;
    }
    final itemStart = _rowPadding + index * (_cardWidth + _cardSpacing);
    final itemCenter = itemStart + _cardWidth / 2;
    final scrollOffset = _scrollController.offset;
    final viewportCenter = scrollOffset + viewportWidth / 2;
    final distance = (itemCenter - viewportCenter).abs();
    final maxDistance = viewportWidth / 2 + _cardWidth;
    final t = (distance / maxDistance).clamp(0.0, 1.0);
    // Scale from 1.0 (centered) down to 0.92 (at the edges) — subtle by
    // design; anything stronger reads as a bug rather than a depth cue.
    return 1.0 - (t * 0.08);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _rowPadding),
          child: Text(widget.title, style: AppTypography.titleLg),
        ),
        const SizedBox(height: AppSpacing.md),
        if (widget.isLoading)
          ShimmerPosterRow(performanceMode: widget.performanceMode)
        else if (widget.movies.isEmpty)
          const _EmptyRow()
        else
          SizedBox(
            height: 230,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: _rowPadding),
                  itemCount: widget.movies.length,
                  separatorBuilder: (_, __) => const SizedBox(width: _cardSpacing),
                  itemBuilder: (context, index) {
                    final movie = widget.movies[index];
                    final scale = _scaleForIndex(index, constraints.maxWidth);
                    final opacity = (0.6 + (scale - 0.92) / 0.08 * 0.4).clamp(0.6, 1.0);
                    return Transform.scale(
                      scale: scale,
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: opacity,
                        child: MoviePosterCard(
                          movie: movie,
                          width: _cardWidth,
                          onTap: () => widget.onMovieTap(movie),
                          showProgress: widget.progressForMovie?.call(movie.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 230,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Nothing to show right now.',
            style: AppTypography.bodyMd,
          ),
        ),
      ),
    );
  }
}
