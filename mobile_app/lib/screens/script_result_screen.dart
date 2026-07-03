import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context);
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
              title: Text(result.success ? l.successful : l.failed),
              subtitle: Text(l.exitCodeLabel(result.exitCode)),
            ),
          ),
          const SizedBox(height: 16),

          // stdout
          if (result.stdout.isNotEmpty) ...[
            Text(l.outputStdout, style: Theme.of(context).textTheme.titleSmall),
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
            Text(l.errorStderr, style: Theme.of(context).textTheme.titleSmall),
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
