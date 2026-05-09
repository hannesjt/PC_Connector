import 'package:flutter/material.dart';
import '../models/script_config.dart';

class ScriptResultScreen extends StatelessWidget {
  final String scriptName;
  final ScriptResult result;

  const ScriptResultScreen({
    super.key,
    required this.scriptName,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(scriptName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status
          Card(
            color: result.success
                ? Colors.green.withValues(alpha: 0.15)
                : Colors.red.withValues(alpha: 0.15),
            child: ListTile(
              leading: Icon(
                result.success ? Icons.check_circle : Icons.error,
                color: result.success ? Colors.green : Colors.red,
              ),
              title: Text(result.success ? 'Erfolgreich' : 'Fehlgeschlagen'),
              subtitle: Text('Exit-Code: ${result.exitCode}'),
            ),
          ),
          const SizedBox(height: 16),

          // stdout
          if (result.stdout.isNotEmpty) ...[
            Text('Ausgabe (stdout)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                result.stdout,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.greenAccent,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // stderr
          if (result.stderr.isNotEmpty) ...[
            Text('Fehler (stderr)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                result.stderr,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
