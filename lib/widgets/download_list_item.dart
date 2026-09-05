import 'package:flutter/material.dart';

import '../models/download_item.dart';
import '../utils/format_utils.dart';

class DownloadListItem extends StatelessWidget {
  const DownloadListItem({
    super.key,
    required this.item,
    this.onPlay,
    this.onShare,
    this.onDelete,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onTap,
  });

  final DownloadItem item;
  final VoidCallback? onPlay;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 64,
                  height: 64,
                  color: scheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.movie_creation_outlined,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title?.isNotEmpty == true ? item.title! : item.filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    if (item.status == DownloadStatus.downloading ||
                        item.status == DownloadStatus.connecting) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: item.progress > 0 ? item.progress : null,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _trailingActions(context),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    switch (item.status) {
      case DownloadStatus.completed:
        return [
          FormatUtils.formatBytes(item.fileSizeBytes),
          if (item.durationMs != null)
            FormatUtils.formatDuration(Duration(milliseconds: item.durationMs!)),
        ].join(' • ');
      case DownloadStatus.downloading:
        return '${FormatUtils.formatPercent(item.progress)} • Downloading';
      case DownloadStatus.connecting:
        return 'Connecting...';
      case DownloadStatus.preparing:
        return 'Preparing...';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  Widget _trailingActions(BuildContext context) {
    switch (item.status) {
      case DownloadStatus.downloading:
      case DownloadStatus.connecting:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onPause != null)
              IconButton(icon: const Icon(Icons.pause_rounded), onPressed: onPause),
            if (onCancel != null)
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: onCancel),
          ],
        );
      case DownloadStatus.paused:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onResume != null)
              IconButton(
                  icon: const Icon(Icons.play_arrow_rounded), onPressed: onResume),
            if (onCancel != null)
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: onCancel),
          ],
        );
      case DownloadStatus.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onPlay != null)
              IconButton(
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  onPressed: onPlay),
            if (onShare != null)
              IconButton(icon: const Icon(Icons.share_rounded), onPressed: onShare),
            if (onDelete != null)
              IconButton(
                  icon: const Icon(Icons.delete_outline_rounded), onPressed: onDelete),
          ],
        );
      case DownloadStatus.failed:
      case DownloadStatus.cancelled:
        return onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline_rounded), onPressed: onDelete)
            : const SizedBox.shrink();
    }
  }
}
