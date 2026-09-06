import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/movie_model.dart';
import '../../providers/search_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/movie_poster_card.dart';
import '../details/movie_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 300) {
      context.read<SearchProvider>().loadMore();
    }
  }

  void _openDetails(Movie movie) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MovieDetailsScreen(movie: movie)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: search.onQueryChanged,
              decoration: InputDecoration(
                hintText: 'Search movies, actors, genres...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          search.onQueryChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(child: _buildBody(search)),
        ],
      ),
    );
  }

  Widget _buildBody(SearchProvider search) {
    switch (search.state) {
      case SearchState.idle:
        return const _SearchIdleState();
      case SearchState.loading:
        return const Center(child: CircularProgressIndicator());
      case SearchState.error:
        return const _SearchMessageState(
          icon: Icons.wifi_off_rounded,
          message: "Couldn't search right now. Check your connection and try again.",
        );
      case SearchState.empty:
        return const _SearchMessageState(
          icon: Icons.search_off_rounded,
          message: 'No results found. Try a different title.',
        );
      case SearchState.loaded:
        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.lg),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.6,
          ),
          itemCount: search.results.length + (search.isLoadingMore ? 3 : 0),
          itemBuilder: (context, index) {
            if (index >= search.results.length) {
              return const _LoadingPosterPlaceholder();
            }
            final movie = search.results[index];
            return MoviePosterCard(
              movie: movie,
              width: double.infinity,
              onTap: () => _openDetails(movie),
            );
          },
        );
    }
  }
}

class _SearchIdleState extends StatelessWidget {
  const _SearchIdleState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.movie_filter_outlined, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Search for movies by title, cast, or genre.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchMessageState extends StatelessWidget {
  const _SearchMessageState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.lg),
            Text(message, textAlign: TextAlign.center, style: AppTypography.bodyMd),
          ],
        ),
      ),
    );
  }
}

class _LoadingPosterPlaceholder extends StatelessWidget {
  const _LoadingPosterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
    );
  }
}
