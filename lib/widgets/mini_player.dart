import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../screens/now_playing_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final song = player.currentSong;
        if (song == null) return const SizedBox.shrink();

        final progress = player.duration.inMilliseconds > 0
            ? player.position.inMilliseconds / player.duration.inMilliseconds
            : 0.0;

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const NowPlayingScreen(),
                transitionsBuilder: (_, animation, __, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.15),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                transitionDuration: const Duration(milliseconds: 320),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: context.colors.surfaceElevated,
              border: Border(top: BorderSide(color: context.colors.stroke, width: 1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 2,
                  backgroundColor: context.colors.stroke,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentViolet),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: song.thumbnailUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 40,
                            height: 40,
                            color: context.colors.surfaceCard,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: context.colors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_previous, color: context.colors.textPrimary),
                        onPressed: player.hasPrevious ? () => player.playPrevious() : null,
                      ),
                      IconButton(
                        icon: Icon(
                          player.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: AppColors.accentViolet,
                          size: 32,
                        ),
                        onPressed: () => player.togglePlayPause(),
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_next, color: context.colors.textPrimary),
                        onPressed: player.hasNext ? () => player.playNext() : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
