import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_row.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/song_options_sheet.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  late final SearchProvider _searchProvider;

  @override
  void initState() {
    super.initState();
    _searchProvider = SearchProvider();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _searchProvider,
      child: Scaffold(
        backgroundColor: context.colors.bgPrimary,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(
                  'Search',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.surfaceCard,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: context.colors.stroke),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: context.colors.textPrimary),
                    textInputAction: TextInputAction.search,
                    onChanged: (value) {
                      setState(() {});
                      context.read<SearchProvider>().onQueryChanged(value);
                    },
                    onSubmitted: (value) {
                      context.read<SearchProvider>().searchImmediately(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search, or describe a mood…',
                      hintStyle: TextStyle(color: context.colors.textTertiary),
                      prefixIcon: Icon(Icons.search, color: context.colors.textSecondary),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: context.colors.textSecondary),
                              onPressed: () {
                                _controller.clear();
                                setState(() {});
                                context.read<SearchProvider>().reset();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Consumer<SearchProvider>(
                  builder: (context, search, _) => _buildResults(context, search),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, SearchProvider search) {
    switch (search.status) {
      case SearchStatus.idle:
        return const EmptyStateView(
          title: 'What are you in the mood for?',
          subtitle: 'Search by song, artist, or vibe',
          icon: Icons.graphic_eq_rounded,
        );
      case SearchStatus.loading:
        return const LoadingView();
      case SearchStatus.error:
      case SearchStatus.offline:
        return EmptyStateView(
          title: 'Something went wrong',
          subtitle: search.errorMessage ?? 'Please try again',
          icon: Icons.wifi_off_rounded,
          actionLabel: 'Retry',
          onAction: () => search.retry(),
        );
      case SearchStatus.empty:
        return const EmptyStateView(
          title: 'No results found',
          subtitle: 'Try a different search term',
          icon: Icons.search_off_rounded,
        );
      case SearchStatus.success:
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: search.results.length,
          itemBuilder: (context, index) {
            final song = search.results[index];
            return SongRow(
              song: song,
              onTap: () {
                context.read<PlayerProvider>().playFromQueue(search.results, index);
              },
              onMoreTap: () {
                showSongOptionsSheet(context, song);
              },
            );
          },
        );
    }
  }
}
