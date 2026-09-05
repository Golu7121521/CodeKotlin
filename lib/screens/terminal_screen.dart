import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../services/terminal_service.dart';
import '../theme/app_theme.dart';

class TerminalScreen extends StatefulWidget {
  final Project project;
  const TerminalScreen({super.key, required this.project});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  late final TerminalService _term;
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<String> _lines = [];

  @override
  void initState() {
    super.initState();
    _term = TerminalService(widget.project);
    _lines.add('FlutIDE terminal — type "help" for commands.');
  }

  Future<void> _submit(String text) async {
    if (text.trim().isEmpty) return;
    setState(() => _lines.add('\$ $text'));
    _inputCtrl.clear();
    final output = await _term.run(text);
    setState(() {
      if (output == '\x1B[CLEAR]') {
        _lines.clear();
      } else if (output.isNotEmpty) {
        _lines.add(output);
      }
    });
    await Future.delayed(const Duration(milliseconds: 50));
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terminal · ${widget.project.name}', style: const TextStyle(fontSize: 14)),
        actions: [
          IconButton(
            iconSize: AppSizes.toolbarIcon,
            tooltip: 'Quick: push',
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: () => _submit('push'),
          ),
          IconButton(
            iconSize: AppSizes.toolbarIcon,
            tooltip: 'Quick: build',
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () => _submit('build'),
          ),
          IconButton(
            iconSize: AppSizes.toolbarIcon,
            tooltip: 'Quick: status',
            icon: const Icon(Icons.refresh),
            onPressed: () => _submit('status'),
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFF0C0C0C),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(10),
                itemCount: _lines.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: SelectableText(
                    _lines[i],
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: AppSizes.fontTerminal,
                      color: Color(0xFF7CFC93),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              color: const Color(0xFF161616),
              child: Row(
                children: [
                  const Text('\$ ',
                      style: TextStyle(
                          fontFamily: 'monospace', color: Color(0xFF7CFC93), fontSize: 13)),
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 13, color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'ls, cd, push, build, status, help ...',
                        hintStyle: TextStyle(fontSize: 12, color: Colors.white30),
                      ),
                      onSubmitted: _submit,
                    ),
                  ),
                  IconButton(
                    iconSize: AppSizes.tabIcon,
                    icon: const Icon(Icons.keyboard_return, color: Color(0xFF7CFC93)),
                    onPressed: () => _submit(_inputCtrl.text),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
