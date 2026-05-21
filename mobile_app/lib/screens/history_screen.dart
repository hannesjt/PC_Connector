import 'package:flutter/material.dart';

import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  final ApiService api;
  const HistoryScreen({super.key, required this.api});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.api.getHistory();
      if (!mounted) return;
      setState(() {
        _entries = data;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verlauf löschen'),
        content: const Text('Gesamten Verlauf löschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.api.clearHistory();
      setState(() => _entries = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Skript-Verlauf'),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clear,
              tooltip: 'Verlauf löschen',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('Kein Verlauf'))
              : ListView.builder(
                  itemCount: _entries.length,
                  itemBuilder: (ctx, i) {
                    final e = _entries[i];
                    final success = e['success'] == true;
                    final tsRaw = e['timestamp'];
                    String dateStr;
                    try {
                      final dt = DateTime.fromMillisecondsSinceEpoch(
                          ((tsRaw as num) * 1000).toInt());
                      dateStr =
                          '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  '
                          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    } catch (_) {
                      dateStr = tsRaw?.toString() ?? '';
                    }
                    return ListTile(
                      leading: Icon(
                        success ? Icons.check_circle : Icons.error,
                        color: success ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        (e['script_name'] ?? e['script'] ?? 'Unbekannt') as String),
                      subtitle: Text(dateStr),
                      trailing: (e['stderr'] as String? ?? '').isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.info_outline),
                              onPressed: () => _showOutput(e),
                            )
                          : null,
                    );
                  },
                ),
    );
  }

  void _showOutput(Map<String, dynamic> entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text((entry['script_name'] ?? entry['script'] ?? '') as String),
        content: SingleChildScrollView(
          child: Text(entry['stderr'] as String? ?? '(kein Output)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}
