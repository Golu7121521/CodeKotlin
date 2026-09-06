import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';

class SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const SongCard({super.key, required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: song.thumbnailUrl,
                width: 140,
                height: 140,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 140,
                  height: 140,
                  color: context.colors.surfaceElevated,
                ),
                errorWidget: (context, url, error) => Container(
                  width: 140,
                  height: 140,
                  color: context.colors.surfaceElevated,
                  child: Icon(Icons.music_note, color: context.colors.textTertiary),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              song.artist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
