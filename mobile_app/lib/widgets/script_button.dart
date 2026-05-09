import 'package:flutter/material.dart';
import '../models/script_config.dart';

class ScriptButton extends StatelessWidget {
  final ScriptConfig script;
  final VoidCallback onPressed;

  const ScriptButton({
    super.key,
    required this.script,
    required this.onPressed,
  });

  IconData _iconFromName(String name) {
    const iconMap = {
      'power_off': Icons.power_settings_new,
      'restart_alt': Icons.restart_alt,
      'games': Icons.games,
      'lock': Icons.lock,
      'backup': Icons.backup,
      'play_arrow': Icons.play_arrow,
      'terminal': Icons.terminal,
      'folder': Icons.folder,
      'download': Icons.download,
      'upload': Icons.upload,
      'desktop_windows': Icons.desktop_windows,
      'monitor': Icons.monitor,
      'tv': Icons.tv,
    };
    return iconMap[name] ?? Icons.play_arrow;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_iconFromName(script.icon), size: 32),
              const SizedBox(height: 8),
              Text(
                script.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
