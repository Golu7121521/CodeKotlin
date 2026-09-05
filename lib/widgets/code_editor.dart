import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:highlight/highlight.dart' as hl;
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/yaml.dart';
import 'package:highlight/languages/xml.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:highlight/languages/kotlin.dart';
import 'package:highlight/languages/gradle.dart';
import '../theme/app_theme.dart';

/// A plain-text editor that colors tokens as you type (keywords, strings,
/// comments, numbers ...). It intentionally does NOT analyze the code for
/// errors - purely cosmetic highlighting, per requirement.
class CodeEditor extends StatefulWidget {
  final String initialContent;
  final String fileName;
  final ValueChanged<String> onChanged;

  const CodeEditor({
    super.key,
    required this.initialContent,
    required this.fileName,
    required this.onChanged,
  });

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  late final TextEditingController _controller;
  late final ScrollController _scrollController;

  static const Map<String, TextStyle> _palette = {
    'keyword': TextStyle(color: Color(0xFFC792EA)),
    'built_in': TextStyle(color: Color(0xFF82AAFF)),
    'string': TextStyle(color: Color(0xFFC3E88D)),
    'comment': TextStyle(color: Color(0xFF616161), fontStyle: FontStyle.italic),
    'number': TextStyle(color: Color(0xFFF78C6C)),
    'literal': TextStyle(color: Color(0xFFF78C6C)),
    'class': TextStyle(color: Color(0xFFFFCB6B)),
    'title': TextStyle(color: Color(0xFF82AAFF)),
    'params': TextStyle(color: Color(0xFFEEFFFF)),
    'meta': TextStyle(color: Color(0xFF89DDFF)),
    'symbol': TextStyle(color: Color(0xFF89DDFF)),
    'attr': TextStyle(color: Color(0xFFC792EA)),
    'tag': TextStyle(color: Color(0xFFF07178)),
    'variable': TextStyle(color: Color(0xFFEEFFFF)),
    'default': TextStyle(color: Color(0xFFEEFFFF)),
  };

  @override
  void initState() {
    super.initState();
    _controller = _HighlightingController(language: _languageFor(widget.fileName));
    _controller.text = widget.initialContent;
    _controller.addListener(() => widget.onChanged(_controller.text));
    _scrollController = ScrollController();
  }

  String _languageFor(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.dart')) return 'dart';
    if (n.endsWith('.yaml') || n.endsWith('.yml')) return 'yaml';
    if (n.endsWith('.xml')) return 'xml';
    if (n.endsWith('.json')) return 'json';
    if (n.endsWith('.md')) return 'markdown';
    if (n.endsWith('.kt')) return 'kotlin';
    if (n.endsWith('.gradle')) return 'gradle';
    return 'plaintext';
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(10),
          child: IntrinsicHeight(
            child: TextField(
              controller: _controller,
              maxLines: null,
              minLines: 30,
              cursorColor: Colors.white,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: AppSizes.fontEditor,
                height: 1.4,
                color: Color(0xFFEEFFFF),
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
              inputFormatters: const [],
              keyboardType: TextInputType.multiline,
            ),
          ),
        ),
      ),
    );
  }
}

/// TextEditingController that overrides buildTextSpan to apply syntax
/// colors based on `highlight` package tokenization, while leaving the
/// actual editable text/selection untouched.
class _HighlightingController extends TextEditingController {
  final String language;
  _HighlightingController({required this.language});

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (language == 'plaintext' || text.isEmpty) {
      return TextSpan(text: text, style: style);
    }
    hl.Result result;
    try {
      result = hl.highlight.parse(text, language: language);
    } catch (_) {
      return TextSpan(text: text, style: style);
    }
    final nodes = result.nodes ?? [];
    final spans = <TextSpan>[];
    void walk(List<hl.Node> nodes, TextStyle? inherited) {
      for (final node in nodes) {
        final className = node.className;
        final nodeStyle = className != null
            ? _CodeEditorState._palette[className] ?? inherited
            : inherited;
        if (node.value != null) {
          spans.add(TextSpan(text: node.value, style: nodeStyle ?? style));
        } else if (node.children != null) {
          walk(node.children!, nodeStyle);
        }
      }
    }

    walk(nodes, style);
    return TextSpan(children: spans, style: style);
  }
}
