import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UrlInputField extends StatefulWidget {
  const UrlInputField({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool enabled;

  @override
  State<UrlInputField> createState() => _UrlInputFieldState();
}

class _UrlInputFieldState extends State<UrlInputField> {
  bool _hasClipboardUrl = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _checkClipboard();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _checkClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    final looksLikeUrl = text.startsWith('http://') || text.startsWith('https://');
    if (mounted) {
      setState(() => _hasClipboardUrl = looksLikeUrl);
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      widget.controller.text = text;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: text.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          maxLines: 1,
          onSubmitted: (_) => widget.onSubmit(),
          decoration: InputDecoration(
            hintText: 'Paste a video link here',
            prefixIcon: const Icon(Icons.link_rounded),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasText)
                  IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => widget.controller.clear(),
                  ),
                if (!hasText)
                  IconButton(
                    tooltip: 'Paste',
                    icon: Icon(
                      Icons.content_paste_rounded,
                      color: _hasClipboardUrl
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onPressed: widget.enabled ? _paste : null,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Paste a publicly accessible video URL',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}
