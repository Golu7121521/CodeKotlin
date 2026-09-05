import 'package:flutter/material.dart';
import '../services/project_service.dart';
import '../theme/app_theme.dart';
import 'editor_screen.dart';

class NewProjectScreen extends StatefulWidget {
  const NewProjectScreen({super.key});

  @override
  State<NewProjectScreen> createState() => _NewProjectScreenState();
}

class _NewProjectScreenState extends State<NewProjectScreen> {
  final _nameCtrl = TextEditingController();
  bool _creating = false;
  String? _error;

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter a project name');
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final project = await ProjectService.createProject(_nameCtrl.text.trim());
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => EditorScreen(project: project)),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Flutter Project', style: TextStyle(fontSize: 15))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Project name', style: TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 6),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'my_awesome_app',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'This creates the standard Flutter folder structure (lib, test, android, ios, web) '
              'plus a ready-to-use .github/workflows/flutter_build.yml, so you can build an APK '
              'via GitHub Actions right away.',
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: AppSizes.smallButton + 8,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _creating ? null : _create,
                icon: _creating
                    ? const SizedBox(
                        height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add, size: AppSizes.tabIcon),
                label: const Text('Create Project', style: TextStyle(fontSize: 13)),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
