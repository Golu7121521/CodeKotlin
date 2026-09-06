import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/song.dart';
import '../theme/app_theme.dart';

class SongRow extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;
  final bool isActive;

  const SongRow({
    super.key,
    required this.song,
    required this.onTap,
    this.onMoreTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: song.thumbnailUrl,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 52,
                  height: 52,
                  color: context.colors.surfaceElevated,
                ),
                errorWidget: (context, url, error) => Container(
                  width: 52,
                  height: 52,
                  color: context.colors.surfaceElevated,
                  child: Icon(Icons.music_note, size: 20, color: context.colors.textTertiary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? AppColors.accentViolet : context.colors.textPrimary,
                      fontSize: 15,
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
            if (onMoreTap != null)
              IconButton(
                icon: Icon(Icons.more_vert, color: context.colors.textSecondary),
                onPressed: onMoreTap,
              ),
          ],
        ),
      ),
    );
  }
}
