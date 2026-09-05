import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/storage_service.dart';
import '../services/archive_service.dart';
import '../theme/app_theme.dart';
import 'new_project_screen.dart';
import 'editor_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Project> _projects = [];
  bool _loading = true;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await StorageService.loadProjects();
    setState(() {
      _projects = list;
      _loading = false;
    });
  }

  Future<void> _importProject() async {
    setState(() => _importing = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result == null || result.files.single.path == null) return;
      final project = await ArchiveService.importZip(result.files.single.path!);
      await _load();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditorScreen(project: project)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _openNewProject() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const NewProjectScreen()));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FlutIDE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            iconSize: AppSizes.toolbarIcon,
            tooltip: 'Import .zip project',
            icon: _importing
                ? const SizedBox(
                    height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.file_upload_outlined),
            onPressed: _importing ? null : _importProject,
          ),
          IconButton(
            iconSize: AppSizes.toolbarIcon,
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.folder_open, size: 48, color: Colors.white24),
                      const SizedBox(height: 12),
                      const Text('No projects yet', style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _openNewProject,
                        icon: const Icon(Icons.add, size: AppSizes.tabIcon),
                        label: const Text('New Project', style: TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _projects.length,
                  itemBuilder: (_, i) {
                    final proj = _projects[i];
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.flutter_dash, size: 22, color: Color(0xFF4FC3F7)),
                      title: Text(proj.name, style: const TextStyle(fontSize: 14)),
                      subtitle: Text(
                        proj.githubRepo ?? 'not linked to GitHub',
                        style: const TextStyle(fontSize: 11, color: Colors.white38),
                      ),
                      trailing: PopupMenuButton<String>(
                        iconSize: AppSizes.tabIcon,
                        onSelected: (v) async {
                          if (v == 'delete') {
                            await StorageService.removeProject(proj);
                            _load();
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'delete', child: Text('Remove from list', style: TextStyle(fontSize: 13))),
                        ],
                      ),
                      onTap: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => EditorScreen(project: proj))),
                    );
                  },
                ),
      floatingActionButton: _projects.isEmpty
          ? null
          : FloatingActionButton.small(
              onPressed: _openNewProject,
              child: const Icon(Icons.add, size: 20),
            ),
    );
  }
}
