import 'package:flutter/material.dart';
import '../services/template_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, String> _values = {};
  bool _loading = true;

  final _labels = {
    'main_dart': 'lib/main.dart',
    'pubspec_yaml': 'pubspec.yaml',
    'workflow_yml': 'GitHub Actions workflow',
    'gitignore': '.gitignore',
    'analysis_options': 'analysis_options.yaml',
    'readme': 'README.md',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await TemplateService.loadAll();
    setState(() {
      _values = v;
      _loading = false;
    });
  }

  Future<void> _editTemplate(String id) async {
    final ctrl = TextEditingController(text: _values[id]);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(_labels[id]!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                  IconButton(
                    iconSize: AppSizes.tabIcon,
                    tooltip: 'Reset to default',
                    icon: const Icon(Icons.restore),
                    onPressed: () {
                      ctrl.text = TemplateService.defaultOf(id);
                    },
                  ),
                ],
              ),
              const Divider(height: 8),
              SizedBox(
                height: 380,
                child: TextField(
                  controller: ctrl,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, ctrl.text),
                    child: const Text('Save', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      await TemplateService.save(id, result);
      setState(() => _values[id] = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: const Text('Settings', style: TextStyle(fontSize: 15))),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              'Default files used every time you create a new project. Edit them here to change what gets generated.',
              style: TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ),
          for (final id in _labels.keys)
            ListTile(
              dense: true,
              leading: const Icon(Icons.description_outlined, size: AppSizes.tabIcon),
              title: Text(_labels[id]!, style: const TextStyle(fontSize: 13)),
              trailing: const Icon(Icons.chevron_right, size: AppSizes.tabIcon),
              onTap: () => _editTemplate(id),
            ),
        ],
      ),
    );
  }
}
