import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

class VolumeControlSheet extends StatefulWidget {
  final ApiService api;
  const VolumeControlSheet({super.key, required this.api});

  @override
  State<VolumeControlSheet> createState() => _VolumeControlSheetState();
}

class _VolumeControlSheetState extends State<VolumeControlSheet> {
  double _level = 0.5;
  bool _muted = false;
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadVolume();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadVolume() async {
    try {
      final data = await widget.api.getVolume();
      if (!mounted) return;
      setState(() {
        _level = (data['level'] as num).toDouble();
        _muted = data['muted'] as bool;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onVolumeChanged(double val) {
    setState(() => _level = val);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 80), () {
      widget.api.setVolume(val).catchError((_) {});
    });
  }

  void _toggleMute() {
    final newMuted = !_muted;
    setState(() => _muted = newMuted);
    widget.api.setMute(newMuted).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).volume,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          if (_loading)
            const CircularProgressIndicator()
          else ...[
            Row(
              children: [
                IconButton(
                  icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                  onPressed: _toggleMute,
                  iconSize: 28,
                ),
                Expanded(
                  child: Slider(
                    value: _muted ? 0 : _level,
                    onChanged: _muted ? null : _onVolumeChanged,
                    min: 0,
                    max: 1,
                  ),
                ),
                SizedBox(
                  width: 42,
                  child: Text(
                    '${(_level * 100).round()}%',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

Future<void> showVolumeSheet(BuildContext context, ApiService api) {
  return showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => VolumeControlSheet(api: api),
  );
}
