import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song.dart';
import '../providers/home_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../utils/time_util.dart';
import '../widgets/song_card.dart';
import '../widgets/empty_state_view.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeProvider _homeProvider;

  @override
  void initState() {
    super.initState();
    _homeProvider = HomeProvider();
    _homeProvider.loadHome();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _homeProvider,
      child: Scaffold(
        backgroundColor: context.colors.bgPrimary,
        body: SafeArea(
          child: Consumer<HomeProvider>(
            builder: (context, home, _) {
              return RefreshIndicator(
                onRefresh: () => home.loadHome(),
                color: AppColors.accentViolet,
                child: _buildBody(context, home),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeProvider home) {
    if (home.status == HomeStatus.loading) {
      return const LoadingView();
    }

    if (home.status == HomeStatus.error || home.status == HomeStatus.offline) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          EmptyStateView(
            title: 'Something went wrong',
            subtitle: 'Please try again',
            icon: Icons.wifi_off_rounded,
            actionLabel: 'Retry',
            onAction: () => home.loadHome(),
          ),
        ],
      );
    }

    if (home.status == HomeStatus.empty) {
      return ListView(
        children: [
          const SizedBox(height: 100),
          EmptyStateView(
            title: 'Your sound, awaiting',
            subtitle: 'Search a song or artist to begin the flow',
            actionLabel: 'Retry',
            onAction: () => home.loadHome(),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _buildTopBar(context),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            TimeUtil.greeting(),
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (home.featuredSong != null) _buildHeroCard(context, home.featuredSong!),
        const SizedBox(height: 8),
        for (final section in home.sections)
          if (section.songs.isNotEmpty) _buildSection(context, section.title, section.songs),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Synesthesia',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.search_rounded, color: context.colors.textPrimary),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, Song heroSong) {
    return GestureDetector(
      onTap: () {
        final player = context.read<PlayerProvider>();
        player.playFromQueue([heroSong], 0);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: AppColors.heroGradient,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Opacity(
                  opacity: 0.5,
                  child: CachedNetworkImage(
                    imageUrl: heroSong.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.2),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Featured Track',
                    style: TextStyle(
                      color: Color(0xFFDDD5FF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    heroSong.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    heroSong.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFDDD5FF), fontSize: 13),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Song> songs) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              title,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return SongCard(
                  song: song,
                  onTap: () {
                    final player = context.read<PlayerProvider>();
                    player.playFromQueue(List.from(songs), index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
