import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';

class ClipboardSheet extends StatefulWidget {
  final ApiService api;
  const ClipboardSheet({super.key, required this.api});

  @override
  State<ClipboardSheet> createState() => _ClipboardSheetState();
}

class _ClipboardSheetState extends State<ClipboardSheet> {
  final _controller = TextEditingController();
  String _pcClipboard = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPcClipboard();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPcClipboard() async {
    try {
      final text = await widget.api.getClipboard();
      if (!mounted) return;
      setState(() {
        _pcClipboard = text;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendToPC() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      await widget.api.setClipboard(text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('In PC-Zwischenablage kopiert')),
      );
      _controller.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pasteFromPhone() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _controller.text = data.text!;
    }
  }

  Future<void> _copyToPhone() async {
    await Clipboard.setData(ClipboardData(text: _pcClipboard));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('In Handy-Zwischenablage kopiert')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Zwischenablage', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          // PC clipboard content
          Text('PC-Zwischenablage:', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            constraints: const BoxConstraints(maxHeight: 100),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _loading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : SingleChildScrollView(
                    child: Text(
                      _pcClipboard.isEmpty ? '(leer)' : _pcClipboard,
                      style: TextStyle(
                        color: _pcClipboard.isEmpty ? Colors.grey : null,
                      ),
                    ),
                  ),
          ),
          if (_pcClipboard.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _copyToPhone,
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Auf Handy kopieren'),
              ),
            ),
          const SizedBox(height: 12),

          // Send to PC
          Text('An PC senden:', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Text eingeben...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  IconButton(
                    onPressed: _pasteFromPhone,
                    icon: const Icon(Icons.content_paste),
                    tooltip: 'Einfügen',
                  ),
                  IconButton(
                    onPressed: _sendToPC,
                    icon: const Icon(Icons.send),
                    tooltip: 'An PC senden',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

Future<void> showClipboardSheet(BuildContext context, ApiService api) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ClipboardSheet(api: api),
  );
}
