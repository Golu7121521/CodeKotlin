import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../theme/app_theme.dart';
import '../utils/time_util.dart';
import '../widgets/add_to_playlist_sheet.dart';
import 'queue_screen.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        final song = player.currentSong;

        if (song == null) {
          // Song ended/queue cleared while this screen was open.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        final library = context.watch<LibraryProvider>();
        final isFavorite = library.isFavorite(song);

        final progress = player.duration.inMilliseconds > 0
            ? player.position.inMilliseconds / player.duration.inMilliseconds
            : 0.0;

        return Scaffold(
          backgroundColor: context.colors.bgPrimary,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.keyboard_arrow_down, color: context.colors.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          'The Canvas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.more_vert, color: context.colors.textPrimary),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36),
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CachedNetworkImage(
                              imageUrl: song.thumbnailUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorWidget: (_, __, ___) => Container(
                                color: context.colors.surfaceElevated,
                                child: Icon(Icons.music_note,
                                    size: 64, color: context.colors.textTertiary),
                              ),
                            ),
                          ),
                          if (player.isBuffering)
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.colors.textPrimary,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              player.isBuffering
                                  ? 'Tuning in…'
                                  : player.isPlaying
                                      ? 'Now streaming'
                                      : 'Paused',
                              style: const TextStyle(
                                color: AppColors.accentCyan,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? AppColors.accentMagenta : context.colors.textPrimary,
                        ),
                        onPressed: () => context.read<LibraryProvider>().toggleFavorite(song),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        ),
                        child: Slider(
                          value: progress.clamp(0.0, 1.0),
                          onChanged: (value) {
                            final newPosition = Duration(
                              milliseconds: (value * player.duration.inMilliseconds).round(),
                            );
                            player.seekTo(newPosition);
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            TimeUtil.formatDuration(player.position),
                            style: TextStyle(color: context.colors.textTertiary, fontSize: 11),
                          ),
                          Text(
                            TimeUtil.formatDuration(player.duration),
                            style: TextStyle(color: context.colors.textTertiary, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.shuffle,
                          color: player.shuffleEnabled
                              ? AppColors.accentViolet
                              : context.colors.textSecondary,
                        ),
                        onPressed: () => player.toggleShuffle(),
                      ),
                      IconButton(
                        iconSize: 36,
                        icon: Icon(Icons.skip_previous, color: context.colors.textPrimary),
                        onPressed: player.hasPrevious ? () => player.playPrevious() : null,
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.playButtonGradient,
                        ),
                        child: IconButton(
                          iconSize: 40,
                          icon: Icon(
                            player.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: () => player.togglePlayPause(),
                        ),
                      ),
                      IconButton(
                        iconSize: 36,
                        icon: Icon(Icons.skip_next, color: context.colors.textPrimary),
                        onPressed: player.hasNext ? () => player.playNext() : null,
                      ),
                      IconButton(
                        icon: Icon(
                          player.repeatMode == RepeatMode.one
                              ? Icons.repeat_one
                              : Icons.repeat,
                          color: player.repeatMode == RepeatMode.off
                              ? context.colors.textSecondary
                              : AppColors.accentViolet,
                        ),
                        onPressed: () => player.cycleRepeatMode(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () => showAddToPlaylistSheet(context, song),
                        icon: Icon(Icons.playlist_add, size: 18, color: context.colors.textSecondary),
                        label: Text(
                          'Add to Playlist',
                          style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const QueueScreen()),
                          );
                        },
                        icon: Icon(Icons.queue_music, size: 18, color: context.colors.textSecondary),
                        label: Text(
                          'Queue',
                          style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
                        ),
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
