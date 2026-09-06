import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_view.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, player, _) {
        return Scaffold(
          backgroundColor: context.colors.bgSecondary,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: context.colors.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          'Queue',
                          style: TextStyle(
                            color: context.colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (player.queue.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            player.clearQueue();
                            Navigator.of(context).pop();
                          },
                          child: const Text('Clear', style: TextStyle(color: AppColors.errorRed)),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: player.queue.isEmpty
                      ? const EmptyStateView(
                          title: 'Queue is empty',
                          subtitle: 'Play a song to build your queue',
                          icon: Icons.queue_music,
                        )
                      : ListView.builder(
                          itemCount: player.queue.length,
                          itemBuilder: (context, index) {
                            final song = player.queue[index];
                            final isActive = index == player.currentIndex;
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: song.thumbnailUrl,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    width: 44,
                                    height: 44,
                                    color: context.colors.surfaceCard,
                                  ),
                                ),
                              ),
                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isActive
                                      ? AppColors.accentViolet
                                      : context.colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                song.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.close, size: 18, color: context.colors.textSecondary),
                                onPressed: () => player.removeFromQueue(index),
                              ),
                              onTap: () => player.playQueueIndex(index),
                            );
                          },
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
