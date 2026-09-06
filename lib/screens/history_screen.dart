import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/download_item.dart';
import '../providers/downloads_provider.dart';
import '../widgets/download_list_item.dart';
import '../widgets/empty_state.dart';

enum _SortOption { newest, oldest, largest, smallest, name }
enum _FilterOption { all, recent, large }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _SortOption _sort = _SortOption.newest;
  _FilterOption _filter = _FilterOption.all;
  bool _gridView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DownloadItem> _applyFiltersAndSort(List<DownloadItem> items) {
    var result = List<DownloadItem>.from(items);

    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      result = result
          .where((i) =>
              i.filename.toLowerCase().contains(q) ||
              (i.title?.toLowerCase().contains(q) ?? false) ||
              i.url.toLowerCase().contains(q))
          .toList();
    }

    switch (_filter) {
      case _FilterOption.all:
        break;
      case _FilterOption.recent:
        final cutoff = DateTime.now().subtract(const Duration(days: 7));
        result = result.where((i) => i.createdAt.isAfter(cutoff)).toList();
        break;
      case _FilterOption.large:
        result = result.where((i) => (i.fileSizeBytes ?? 0) > 50 * 1024 * 1024).toList();
        break;
    }

    switch (_sort) {
      case _SortOption.newest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortOption.oldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _SortOption.largest:
        result.sort((a, b) => (b.fileSizeBytes ?? 0).compareTo(a.fileSizeBytes ?? 0));
        break;
      case _SortOption.smallest:
        result.sort((a, b) => (a.fileSizeBytes ?? 0).compareTo(b.fileSizeBytes ?? 0));
        break;
      case _SortOption.name:
        result.sort((a, b) => a.filename.toLowerCase().compareTo(b.filename.toLowerCase()));
        break;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: Icon(_gridView ? Icons.view_list_rounded : Icons.grid_view_rounded),
            onPressed: () => setState(() => _gridView = !_gridView),
          ),
          PopupMenuButton<_SortOption>(
            icon: const Icon(Icons.sort_rounded),
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (context) => const [
              PopupMenuItem(value: _SortOption.newest, child: Text('Newest')),
              PopupMenuItem(value: _SortOption.oldest, child: Text('Oldest')),
              PopupMenuItem(value: _SortOption.largest, child: Text('Largest')),
              PopupMenuItem(value: _SortOption.smallest, child: Text('Smallest')),
              PopupMenuItem(value: _SortOption.name, child: Text('Name')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by filename, title, or URL',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _filter == _FilterOption.all,
                    onTap: () => setState(() => _filter = _FilterOption.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Recent',
                    selected: _filter == _FilterOption.recent,
                    onTap: () => setState(() => _filter = _FilterOption.recent),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Large files',
                    selected: _filter == _FilterOption.large,
                    onTap: () => setState(() => _filter = _FilterOption.large),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<DownloadsProvider>(
              builder: (context, provider, _) {
                final items = _applyFiltersAndSort(provider.all);
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'No history yet',
                    subtitle: 'Videos you process will show up here.',
                  );
                }
                return _gridView
                    ? _buildGrid(context, items, provider)
                    : _buildList(context, items, provider);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<DownloadItem> items, DownloadsProvider provider) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _historyItem(context, items[index], provider),
    );
  }

  Widget _buildGrid(BuildContext context, List<DownloadItem> items, DownloadsProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: item.localPath != null ? () => OpenFilex.open(item.localPath!) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.movie_creation_outlined,
                      size: 36,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    item.title?.isNotEmpty == true ? item.title! : item.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _historyItem(BuildContext context, DownloadItem item, DownloadsProvider provider) {
    return DownloadListItem(
      item: item,
      onPlay: item.localPath != null ? () => OpenFilex.open(item.localPath!) : null,
      onShare: item.localPath != null
          ? () => SharePlus.instance.share(ShareParams(files: [XFile(item.localPath!)]))
          : null,
      onDelete: () => _confirmDelete(context, provider, item),
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
        title: const Text('Delete this item?'),
        content: Text('Remove "${item.filename}" from history and delete the file.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteItem(item.id, deleteFile: true);
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
