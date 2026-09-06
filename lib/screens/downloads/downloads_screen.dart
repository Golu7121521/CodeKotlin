import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/download_item_model.dart';
import '../../providers/downloads_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DownloadsProvider>().validateDownloads();
    });
  }

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadsProvider>();
    final all = downloads.all;

    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: all.isEmpty
          ? const _EmptyDownloads()
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: all.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => _DownloadRow(item: all[index]),
            ),
    );
  }
}

class _EmptyDownloads extends StatelessWidget {
  const _EmptyDownloads();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.download_outlined, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.lg),
            Text('No downloads yet', style: AppTypography.titleMd),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Downloaded titles will appear here for offline viewing.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd,
            ),
          ],
        ),
      ),
    );
  }
}

/// A single download row. Progress is represented as a subtle glowing
/// ring drawn around the poster thumbnail (rather than a separate linear
/// progress bar taking up its own row), keeping the download-manager
/// list visually calm even with many simultaneous downloads.
class _DownloadRow extends StatelessWidget {
  const _DownloadRow({required this.item});
  final DownloadItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            _ProgressRingThumbnail(item: item),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: AppTypography.titleMd,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(_statusLabel(item), style: AppTypography.bodySm),
                ],
              ),
            ),
            _TrailingAction(item: item),
          ],
        ),
      ),
    );
  }

  String _statusLabel(DownloadItem item) {
    switch (item.status) {
      case DownloadStatus.queued:
        return 'Queued';
      case DownloadStatus.downloading:
        return '${(item.progress * 100).toStringAsFixed(0)}% downloaded';
      case DownloadStatus.paused:
        return 'Paused${item.pauseReason != null ? ' \u2022 ${item.pauseReason}' : ''}';
      case DownloadStatus.downloaded:
        return 'Ready to watch offline';
      case DownloadStatus.failed:
        return 'Download failed';
      case DownloadStatus.expired:
        return 'License expired \u2014 download again';
    }
  }
}

class _ProgressRingThumbnail extends StatelessWidget {
  const _ProgressRingThumbnail({required this.item});
  final DownloadItem item;

  @override
  Widget build(BuildContext context) {
    final showRing = item.status == DownloadStatus.downloading ||
        item.status == DownloadStatus.queued;

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showRing)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: item.progress),
              duration: AppMotion.medium,
              builder: (context, value, _) => SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: item.status == DownloadStatus.queued ? null : value,
                  strokeWidth: 2.5,
                  color: AppColors.accentBrand,
                  backgroundColor: AppColors.borderSubtle,
                ),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: SizedBox(
              width: 44,
              height: 44,
              child: item.posterUrl != null
                  ? CachedNetworkImage(imageUrl: item.posterUrl!, fit: BoxFit.cover)
                  : Container(color: AppColors.bgSurfaceElevated),
            ),
          ),
        ],
      ),
    );
  }
}

/// Trailing per-row action, varying by download state. Retry (for
/// failed/expired items) and resume (for paused items) both require the
/// original source URL, which is already stored on [DownloadItem] —
/// re-fetching full Movie metadata is intentionally out of scope here
/// since the download manager only needs the URL to restart, not the
/// full catalog record.
class _TrailingAction extends StatelessWidget {
  const _TrailingAction({required this.item});
  final DownloadItem item;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DownloadsProvider>();

    switch (item.status) {
      case DownloadStatus.downloading:
      case DownloadStatus.queued:
        return IconButton(
          icon: const Icon(Icons.pause_rounded),
          onPressed: () => provider.pauseDownload(item.movieId),
        );
      case DownloadStatus.paused:
        return IconButton(
          icon: const Icon(Icons.play_arrow_rounded),
          onPressed: () => provider.resumeDownload(item.movieId),
        );
      case DownloadStatus.downloaded:
        return IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: () => provider.deleteDownload(item.movieId),
        );
      case DownloadStatus.failed:
      case DownloadStatus.expired:
        return IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => provider.resumeDownload(item.movieId),
        );
    }
  }
}
