import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/song_row.dart';
import '../widgets/empty_state_view.dart';

class PlaylistDetailScreen extends StatefulWidget {
  final String playlistName;
  const PlaylistDetailScreen({super.key, required this.playlistName});

  @override
  State<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends State<PlaylistDetailScreen> {
  late String _name;
  List<Song> _songs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _name = widget.playlistName;
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    setState(() => _loading = true);
    final songs = await context.read<LibraryProvider>().getPlaylistSongs(_name);
    setState(() {
      _songs = songs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      _name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: context.colors.textPrimary),
                    onPressed: _showRenameDialog,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: context.colors.textPrimary),
                    onPressed: _showDeleteConfirm,
                  ),
                ],
              ),
            ),
            if (_songs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            context.read<PlayerProvider>().playFromQueue(_songs, 0),
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Play All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentViolet,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final shuffled = List<Song>.from(_songs)..shuffle();
                          context.read<PlayerProvider>().playFromQueue(shuffled, 0);
                        },
                        icon: const Icon(Icons.shuffle, size: 16),
                        label: const Text('Shuffle'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.colors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _loading
                  ? const LoadingView()
                  : _songs.isEmpty
                      ? const EmptyStateView(
                          title: 'This playlist is empty',
                          subtitle: 'Add songs from search or your library',
                          icon: Icons.queue_music,
                        )
                      : ListView.builder(
                          itemCount: _songs.length,
                          itemBuilder: (context, index) {
                            final song = _songs[index];
                            return SongRow(
                              song: song,
                              onTap: () =>
                                  context.read<PlayerProvider>().playFromQueue(_songs, index),
                              onMoreTap: () async {
                                await context
                                    .read<LibraryProvider>()
                                    .removeSongFromPlaylist(_name, song);
                                _loadSongs();
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: _name);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename Playlist'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              final success =
                  await context.read<LibraryProvider>().renamePlaylist(_name, newName);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (success) {
                setState(() => _name = newName);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('A playlist with this name already exists')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "$_name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<LibraryProvider>().deletePlaylist(_name);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
