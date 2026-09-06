import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../theme/app_theme.dart';

void showAddToPlaylistSheet(BuildContext context, Song song) {
  final library = context.read<LibraryProvider>();

  if (library.playlistNames.isEmpty) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('No playlists yet'),
        content: const Text('Create a playlist first from the Library tab.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: context.colors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.stroke,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Add to Playlist',
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          ...library.playlistNames.map((name) {
            return ListTile(
              leading: Icon(Icons.queue_music, color: context.colors.textPrimary),
              title: Text(name, style: TextStyle(color: context.colors.textPrimary)),
              onTap: () async {
                await library.addSongToPlaylist(name, song);
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added to $name')),
                  );
                }
              },
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
