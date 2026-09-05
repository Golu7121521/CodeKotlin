import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../theme/app_theme.dart';

class FileExplorer extends StatefulWidget {
  final String rootPath;
  final ValueChanged<File> onFileTap;

  const FileExplorer({super.key, required this.rootPath, required this.onFileTap});

  @override
  State<FileExplorer> createState() => _FileExplorerState();
}

class _FileExplorerState extends State<FileExplorer> {
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _expanded.add(widget.rootPath);
  }

  IconData _iconFor(FileSystemEntity e) {
    if (e is Directory) return Icons.folder;
    final ext = p.extension(e.path);
    switch (ext) {
      case '.dart':
        return Icons.code;
      case '.yaml':
      case '.yml':
        return Icons.settings_suggest;
      case '.md':
        return Icons.description_outlined;
      case '.json':
        return Icons.data_object;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  List<FileSystemEntity> _children(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return [];
    final items = dir.listSync()
      ..removeWhere((e) => p.basename(e.path).startsWith('.git'));
    items.sort((a, b) {
      final ad = a is Directory, bd = b is Directory;
      if (ad != bd) return ad ? -1 : 1;
      return p.basename(a.path).compareTo(p.basename(b.path));
    });
    return items;
  }

  Widget _buildNode(FileSystemEntity entity, int depth) {
    final isDir = entity is Directory;
    final name = p.basename(entity.path);
    final expanded = _expanded.contains(entity.path);

    final row = InkWell(
      onTap: () {
        if (isDir) {
          setState(() {
            expanded ? _expanded.remove(entity.path) : _expanded.add(entity.path);
          });
        } else {
          widget.onFileTap(entity as File);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(left: 8.0 * depth + 6, top: 5, bottom: 5, right: 6),
        child: Row(
          children: [
            if (isDir)
              Icon(expanded ? Icons.arrow_drop_down : Icons.arrow_right,
                  size: AppSizes.tabIcon)
            else
              const SizedBox(width: AppSizes.tabIcon),
            const SizedBox(width: 2),
            Icon(_iconFor(entity), size: AppSizes.tabIcon, color: Colors.white70),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontSize: 12.5),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    if (!isDir || !expanded) return row;

    final children = _children(entity.path);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row,
        ...children.map((c) => _buildNode(c, depth + 1)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = _children(widget.rootPath);
    return ListView(
      padding: EdgeInsets.zero,
      children: children.map((c) => _buildNode(c, 0)).toList(),
    );
  }
}
