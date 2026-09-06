import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_row.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/song_options_sheet.dart';
import 'playlist_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _activeTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: Consumer<LibraryProvider>(
          builder: (context, library, _) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Text(
                    'Your Library',
                    style: TextStyle(
                      color: context.colors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _buildTab(context, 'Liked Songs', 0),
                      const SizedBox(width: 8),
                      _buildTab(context, 'Playlists', 1),
                      const SizedBox(width: 8),
                      _buildTab(context, 'Recent', 2),
                    ],
                  ),
                ),
                Expanded(child: _buildTabContent(context, library)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, String label, int index) {
    final isSelected = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.playButtonGradient : null,
            color: isSelected ? null : context.colors.surfaceCard,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : context.colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, LibraryProvider library) {
    if (_activeTab == 0) return _buildLikedSongs(context, library);
    if (_activeTab == 1) return _buildPlaylists(context, library);
    return _buildRecentlyPlayed(context, library);
  }

  Widget _buildLikedSongs(BuildContext context, LibraryProvider library) {
    if (library.favorites.isEmpty) {
      return const EmptyStateView(
        title: 'No liked songs yet',
        subtitle: 'Start playing music and save your favorites here',
        icon: Icons.favorite_border,
      );
    }

    return ListView.builder(
      itemCount: library.favorites.length,
      itemBuilder: (context, index) {
        final song = library.favorites[index];
        return SongRow(
          song: song,
          onTap: () => context.read<PlayerProvider>().playFromQueue(library.favorites, index),
          onMoreTap: () => showSongOptionsSheet(context, song),
        );
      },
    );
  }

  Widget _buildRecentlyPlayed(BuildContext context, LibraryProvider library) {
    if (library.recentlyPlayed.isEmpty) {
      return const EmptyStateView(
        title: 'No listening history yet',
        subtitle: 'Songs you play will show up here',
        icon: Icons.history,
      );
    }

    return ListView.builder(
      itemCount: library.recentlyPlayed.length,
      itemBuilder: (context, index) {
        final song = library.recentlyPlayed[index];
        return SongRow(
          song: song,
          onTap: () =>
              context.read<PlayerProvider>().playFromQueue(library.recentlyPlayed, index),
          onMoreTap: () => showSongOptionsSheet(context, song),
        );
      },
    );
  }

  Widget _buildPlaylists(BuildContext context, LibraryProvider library) {
    return ListView(
      children: [
        ListTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppColors.playButtonGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
          title: Text(
            'Create Playlist',
            style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold),
          ),
          onTap: () => _showCreatePlaylistDialog(context, library),
        ),
        if (library.playlistNames.isEmpty)
          const EmptyStateView(
            title: 'No playlists yet',
            subtitle: 'Create a playlist to organize your favorite songs',
            icon: Icons.queue_music,
          )
        else
          ...library.playlistNames.map((name) {
            return FutureBuilder(
              future: library.getPlaylistSongs(name),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return ListTile(
                  leading: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: context.colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.queue_music, color: context.colors.textSecondary),
                  ),
                  title: Text(name, style: TextStyle(color: context.colors.textPrimary)),
                  subtitle: Text(
                    '$count ${count == 1 ? 'song' : 'songs'}',
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PlaylistDetailScreen(playlistName: name)),
                    );
                  },
                );
              },
            );
          }),
      ],
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, LibraryProvider library) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Playlist name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              final success = await library.createPlaylist(name);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('A playlist with this name already exists')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
