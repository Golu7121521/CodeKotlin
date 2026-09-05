import 'package:flutter/material.dart';
import '../services/github_service.dart';
import '../models/project_model.dart';
import '../theme/app_theme.dart';

class GithubSetupScreen extends StatefulWidget {
  final Project project;
  const GithubSetupScreen({super.key, required this.project});

  @override
  State<GithubSetupScreen> createState() => _GithubSetupScreenState();
}

class _GithubSetupScreenState extends State<GithubSetupScreen> {
  final _tokenCtrl = TextEditingController();
  final _repoCtrl = TextEditingController();
  bool _saving = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _repoCtrl.text = widget.project.githubRepo ?? '';
    GithubService.getToken().then((t) {
      if (t != null) _tokenCtrl.text = t;
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await GithubService.saveToken(_tokenCtrl.text.trim());
      widget.project.githubRepo = _repoCtrl.text.trim();
      setState(() => _message = 'Saved. This project is now linked.');
    } catch (e) {
      setState(() => _message = 'Error: $e');
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GitHub Setup', style: TextStyle(fontSize: 15))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Access Token (needs "repo" and "workflow" scopes)',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _tokenCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'ghp_xxxxxxxxxxxxxxxx',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Repository (owner/repo)',
                style: TextStyle(fontSize: 12, color: Colors.white70)),
            const SizedBox(height: 6),
            TextField(
              controller: _repoCtrl,
              decoration: const InputDecoration(
                hintText: 'yourusername/your-repo',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: AppSizes.smallButton + 6,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Link', style: TextStyle(fontSize: 13)),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!, style: const TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
