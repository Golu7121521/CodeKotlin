import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../services/download_service.dart';
import '../theme/app_theme.dart';
import 'add_to_playlist_sheet.dart';

void showSongOptionsSheet(BuildContext context, Song song) {
  showModalBottomSheet(
    context: context,
    backgroundColor: context.colors.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _SongOptionsContent(song: song),
  );
}

class _SongOptionsContent extends StatefulWidget {
  final Song song;
  const _SongOptionsContent({required this.song});

  @override
  State<_SongOptionsContent> createState() => _SongOptionsContentState();
}

class _SongOptionsContentState extends State<_SongOptionsContent> {
  final DownloadService _downloadService = DownloadService();
  DownloadStatus _downloadStatus = DownloadStatus.idle;
  double _downloadProgress = 0;

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final isFavorite = library.isFavorite(widget.song);

    return SafeArea(
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
              widget.song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? AppColors.accentMagenta : context.colors.textPrimary,
            ),
            title: Text(
              isFavorite ? 'Remove from Liked Songs' : 'Add to Liked Songs',
              style: TextStyle(color: context.colors.textPrimary),
            ),
            onTap: () async {
              await context.read<LibraryProvider>().toggleFavorite(widget.song);
            },
          ),
          ListTile(
            leading: Icon(Icons.playlist_add, color: context.colors.textPrimary),
            title: Text('Add to Playlist', style: TextStyle(color: context.colors.textPrimary)),
            onTap: () {
              Navigator.of(context).pop();
              showAddToPlaylistSheet(context, widget.song);
            },
          ),
          ListTile(
            leading: Icon(Icons.queue_music, color: context.colors.textPrimary),
            title: Text('Play Next', style: TextStyle(color: context.colors.textPrimary)),
            onTap: () {
              context.read<PlayerProvider>().playNextInQueue(widget.song);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Added to play next')),
              );
            },
          ),
          _buildDownloadTile(context),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDownloadTile(BuildContext context) {
    if (_downloadStatus == DownloadStatus.downloading) {
      return ListTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            value: _downloadProgress > 0 ? _downloadProgress : null,
            strokeWidth: 2.5,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentViolet),
          ),
        ),
        title: Text(
          'Downloading… ${(_downloadProgress * 100).toStringAsFixed(0)}%',
          style: TextStyle(color: context.colors.textPrimary),
        ),
      );
    }

    if (_downloadStatus == DownloadStatus.completed) {
      return ListTile(
        leading: const Icon(Icons.check_circle, color: AppColors.successGreen),
        title: Text('Downloaded', style: TextStyle(color: context.colors.textPrimary)),
      );
    }

    return ListTile(
      leading: Icon(Icons.download_rounded, color: context.colors.textPrimary),
      title: Text('Download', style: TextStyle(color: context.colors.textPrimary)),
      onTap: () {
        _downloadService.downloadSong(
          widget.song,
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              _downloadStatus = progress.status;
              _downloadProgress = progress.progress;
            });

            if (progress.status == DownloadStatus.failed) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(progress.errorMessage ?? 'Download failed')),
              );
            } else if (progress.status == DownloadStatus.completed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saved to Downloads/Synesthesia')),
              );
            }
          },
        );
      },
    );
  }
}
