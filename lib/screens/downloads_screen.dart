import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/download_item.dart';
import '../providers/downloads_provider.dart';
import '../widgets/download_list_item.dart';
import '../widgets/empty_state.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Downloads'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Failed'),
          ]),
        ),
        body: Consumer<DownloadsProvider>(
          builder: (context, provider, _) {
            return TabBarView(
              children: [
                _DownloadsList(
                  items: provider.active,
                  emptyIcon: Icons.downloading_rounded,
                  emptyTitle: 'No active downloads',
                  emptySubtitle: 'Paste a video URL to get started.',
                ),
                _DownloadsList(
                  items: provider.completed,
                  emptyIcon: Icons.check_circle_outline_rounded,
                  emptyTitle: 'No downloads yet',
                  emptySubtitle: 'Paste a video URL to get started.',
                ),
                _DownloadsList(
                  items: provider.failed,
                  emptyIcon: Icons.error_outline_rounded,
                  emptyTitle: 'No failed downloads',
                  emptySubtitle: 'Failed or cancelled items will appear here.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DownloadsList extends StatelessWidget {
  const _DownloadsList({
    required this.items,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final List<DownloadItem> items;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(icon: emptyIcon, title: emptyTitle, subtitle: emptySubtitle);
    }

    final provider = context.read<DownloadsProvider>();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return DownloadListItem(
          item: item,
          onPlay: item.localPath != null
              ? () => OpenFilex.open(item.localPath!)
              : null,
          onShare: item.localPath != null
              ? () => SharePlus.instance
                  .share(ShareParams(files: [XFile(item.localPath!)]))
              : null,
          onCancel: () => provider.cancelDownload(item.id),
          onDelete: () => _confirmDelete(context, provider, item),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DownloadsProvider provider,
    DownloadItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove download?'),
        content: Text('This will remove "${item.filename}" from the list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteItem(item.id);
    }
  }
}
