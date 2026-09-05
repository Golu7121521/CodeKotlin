import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/movie_model.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/performance_provider.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/content_row.dart';
import '../../widgets/hero_banner.dart';
import '../details/movie_details_screen.dart';
import '../player/video_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogProvider>().loadHome();
    });
  }

  void _openDetails(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MovieDetailsScreen(movie: movie)),
    );
  }

  void _playMovie(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(movie: movie),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final performanceMode = context.watch<PerformanceProvider>().effectiveMode;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: catalog.refresh,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: catalog.heroMovie != null
                  ? HeroBanner(
                      movie: catalog.heroMovie!,
                      onPlay: () => _playMovie(catalog.heroMovie!),
                      onMoreInfo: () => _openDetails(catalog.heroMovie!),
                    )
                  : const AspectRatio(aspectRatio: 2 / 3, child: SizedBox.shrink()),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: AppSpacing.xxl)),
            if (catalog.continueWatching.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: ContentRow(
                  title: 'Continue Watching',
                  movies: catalog.continueWatching,
                  onMovieTap: _openDetails,
                  performanceMode: performanceMode,
                ),
              ),
              SliverToBoxAdapter(child: const SizedBox(height: AppSpacing.xxl)),
            ],
            SliverToBoxAdapter(
              child: ContentRow(
                title: 'Trending Now',
                movies: catalog.trending,
                isLoading: catalog.trendingState == CatalogLoadState.loading,
                onMovieTap: _openDetails,
                performanceMode: performanceMode,
              ),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: AppSpacing.xxl)),
            SliverToBoxAdapter(
              child: ContentRow(
                title: 'Bollywood & Hindi Cinema',
                movies: catalog.bollywood,
                isLoading: catalog.bollywoodState == CatalogLoadState.loading,
                onMovieTap: _openDetails,
                performanceMode: performanceMode,
              ),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: AppSpacing.xxxl)),
          ],
        ),
      ),
    );
  }
}
