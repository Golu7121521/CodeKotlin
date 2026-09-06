import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/movie_model.dart';
import '../../providers/watchlist_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../player/video_player_screen.dart';

class MovieDetailsScreen extends StatefulWidget {
  const MovieDetailsScreen({super.key, required this.movie});

  final Movie movie;

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  final _api = ApiService();
  Movie? _detailedMovie;
  List<CastMember> _cast = [];
  bool _loadingDetails = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    final results = await Future.wait([
      _api.getMovieDetails(widget.movie),
      _api.getCast(widget.movie.id),
    ]);
    if (!mounted) return;
    setState(() {
      _detailedMovie = results[0] as Movie;
      _cast = results[1] as List<CastMember>;
      _loadingDetails = false;
    });
  }

  Movie get _movie => _detailedMovie ?? widget.movie;

  @override
  Widget build(BuildContext context) {
    final watchlist = context.watch<WatchlistProvider>();
    final inList = watchlist.isInList(_movie.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            backgroundColor: AppColors.bgBase,
            leading: const BackButton(),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'movie-backdrop-${_movie.id}',
                // The shared-element transition: the poster card the user
                // tapped morphs into this full-width backdrop. Flutter's
                // Hero widget interpolates position/size automatically
                // using AppMotion.emphasizedDecelerate via the page
                // route's transition (see main.dart's page transitions
                // theme) for the "long emphasized deceleration" specified
                // for hero/macro transitions.
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_movie.backdropUrl != null)
                      CachedNetworkImage(
                        imageUrl: _movie.backdropUrl!,
                        fit: BoxFit.cover,
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
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_movie.title, style: AppTypography.headlineMd),
                  if (_movie.tagline != null && _movie.tagline!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _movie.tagline!,
                      style: AppTypography.bodyMd.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _MetadataBar(movie: _movie),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VideoPlayerScreen(movie: _movie),
                              fullscreenDialog: true,
                            ),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _WatchlistButton(
                        isInList: inList,
                        onTap: () => watchlist.toggle(_movie.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text('Overview', style: AppTypography.titleMd),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_movie.overview, style: AppTypography.bodyLg),
                  const SizedBox(height: AppSpacing.xxl),
                  if (_loadingDetails)
                    const Center(child: CircularProgressIndicator())
                  else if (_cast.isNotEmpty) ...[
                    Text('Cast', style: AppTypography.titleMd),
                    const SizedBox(height: AppSpacing.md),
                    _CastCarousel(cast: _cast),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Metadata bar with exact 8px (space-sm) gaps between rating, year,
/// duration, and quality badges.
class _MetadataBar extends StatelessWidget {
  const _MetadataBar({required this.movie});
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
        if (movie.genres != null)
          ...movie.genres!.take(3).map(
                (g) => Chip(
                  label: Text(g.name),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
      ],
    );
  }
}

class _WatchlistButton extends StatelessWidget {
  const _WatchlistButton({required this.isInList, required this.onTap});
  final bool isInList;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
        child: AnimatedSwitcher(
          duration: AppMotion.small,
          switchInCurve: AppMotion.spring,
          child: Icon(
            isInList ? Icons.check_rounded : Icons.add_rounded,
            key: ValueKey(isInList),
          ),
        ),
      ),
    );
  }
}

/// Cast carousel: rounded-rectangle (not circular) profile crops, chosen
/// so the row reads consistently with the poster-card visual language
/// elsewhere in the app rather than introducing a second, competing
/// "avatar" shape language. Long-press reveals the actor's full name if
/// truncated (shown via a tooltip rather than a modal, to stay
/// lightweight for a secondary interaction).
class _CastCarousel extends StatelessWidget {
  const _CastCarousel({required this.cast});
  final List<CastMember> cast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cast.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final member = cast[index];
          return Tooltip(
            message: '${member.name} as ${member.character}',
            child: SizedBox(
              width: 90,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: SizedBox(
                      width: 90,
                      height: 110,
                      child: member.profileUrl != null
                          ? CachedNetworkImage(
                              imageUrl: member.profileUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => const _CastFallback(),
                            )
                          : const _CastFallback(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSm,
                  ),
                  Text(
                    member.character,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CastFallback extends StatelessWidget {
  const _CastFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgSurfaceElevated,
      alignment: Alignment.center,
      child: const Icon(Icons.person_rounded, color: AppColors.textTertiary),
    );
  }
}
