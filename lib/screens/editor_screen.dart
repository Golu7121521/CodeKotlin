import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../models/project_model.dart';
import '../widgets/file_explorer.dart';
import '../widgets/code_editor.dart';
import '../theme/app_theme.dart';
import 'terminal_screen.dart';
import 'github_setup_screen.dart';
import '../services/archive_service.dart';

class EditorScreen extends StatefulWidget {
  final Project project;
  const EditorScreen({super.key, required this.project});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _OpenTab {
  final File file;
  String content;
  bool dirty = false;
  _OpenTab(this.file, this.content);
}

class _EditorScreenState extends State<EditorScreen> with SingleTickerProviderStateMixin {
  final List<_OpenTab> _tabs = [];
  int _activeIndex = -1;
  bool _explorerOpen = true;

  void _openFile(File file) {
    final existing = _tabs.indexWhere((t) => t.file.path == file.path);
    if (existing != -1) {
      setState(() => _activeIndex = existing);
      return;
    }
    final content = file.readAsStringSync();
    setState(() {
      _tabs.add(_OpenTab(file, content));
      _activeIndex = _tabs.length - 1;
    });
  }

  void _closeTab(int index) {
    setState(() {
      _tabs.removeAt(index);
      if (_activeIndex >= _tabs.length) _activeIndex = _tabs.length - 1;
    });
  }

  Future<void> _saveActive() async {
    if (_activeIndex < 0) return;
    final tab = _tabs[_activeIndex];
    await tab.file.writeAsString(tab.content);
    setState(() => tab.dirty = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${p.basename(tab.file.path)}'), duration: const Duration(seconds: 1)),
      );
    }
  }

  Future<void> _exportProject() async {
    final path = await ArchiveService.exportProject(widget.project);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to $path')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 4,
        title: Text(widget.project.name, style: const TextStyle(fontSize: 14)),
        actions: [
          IconButton(
            iconSize: AppSizes.toolbarIcon,
            tooltip: 'Toggle files',
            icon: const Icon(Icons.folder_outlined),
            onPressed: () => setState(() => _explorerOpen = !_explorerOpen),
          ),
          IconButton(
            iconSize: AppSizes.toolbarIcon,
            tooltip: 'Save',
            icon: const Icon(Icons.save_outlined),
            onPressed: _saveActive,
          ),
          IconButton(
            iconSize: AppSizes.toolbarIcon,
            tooltip: 'Terminal',
            icon: const Icon(Icons.terminal),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => TerminalScreen(project: widget.project))),
          ),
          IconButton(
            iconSize: AppSizes.toolbarIcon,
            tooltip: 'GitHub link',
            icon: const Icon(Icons.link),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => GithubSetupScreen(project: widget.project))),
          ),
          PopupMenuButton<String>(
            iconSize: AppSizes.toolbarIcon,
            onSelected: (v) {
              if (v == 'export') _exportProject();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'export', child: Text('Export project (.zip)', style: TextStyle(fontSize: 13))),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          if (_explorerOpen)
            SizedBox(
              width: 190,
              child: Container(
                color: const Color(0xFF232323),
                child: FileExplorer(rootPath: widget.project.path, onFileTap: _openFile),
              ),
            ),
          if (_explorerOpen) const VerticalDivider(width: 1),
          Expanded(
            child: _tabs.isEmpty
                ? const Center(
                    child: Text('Select a file to start editing',
                        style: TextStyle(color: Colors.white38, fontSize: 13)))
                : Column(
                    children: [
                      SizedBox(
                        height: AppSizes.tabHeight,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _tabs.length,
                          itemBuilder: (_, i) {
                            final tab = _tabs[i];
                            final active = i == _activeIndex;
                            return InkWell(
                              onTap: () => setState(() => _activeIndex = i),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: active ? const Color(0xFF1E1E1E) : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                        color: active ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                        width: 2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(p.basename(tab.file.path),
                                        style: const TextStyle(fontSize: 12)),
                                    if (tab.dirty) ...[
                                      const SizedBox(width: 4),
                                      const Icon(Icons.circle, size: 6, color: Colors.orangeAccent),
                                    ],
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => _closeTab(i),
                                      child: const Icon(Icons.close, size: 14),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: CodeEditor(
                          key: ValueKey(_tabs[_activeIndex].file.path),
                          initialContent: _tabs[_activeIndex].content,
                          fileName: _tabs[_activeIndex].file.path,
                          onChanged: (v) {
                            _tabs[_activeIndex].content = v;
                            _tabs[_activeIndex].dirty = true;
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
