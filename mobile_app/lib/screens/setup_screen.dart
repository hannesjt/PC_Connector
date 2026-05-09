import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/pc_profile.dart';
import '../services/api_service.dart';
import '../services/discovery_service.dart';
import '../services/storage_service.dart';

Future<String> _getDeviceModel() async {
  try {
    final info = await DeviceInfoPlugin().androidInfo;
    final brand = info.brand;
    final model = info.model;
    // Avoid duplicating brand in model (e.g. "google Pixel 10" → "Pixel 10")
    if (model.toLowerCase().startsWith(brand.toLowerCase())) return model;
    return '$brand $model';
  } catch (_) {
    return 'Mein Handy';
  }
}

class SetupScreen extends StatefulWidget {
  final PcProfile? editProfile;

  const SetupScreen({super.key, this.editProfile});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  final _codeCtrl = TextEditingController();

  bool get _isEditing => widget.editProfile != null;
  bool _pairing = false;
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    final p = widget.editProfile;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final storage = StorageService();
    final code = _codeCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (_isEditing) {
      var updated = widget.editProfile!.copyWith(
        name: name.isEmpty ? widget.editProfile!.name : name,
      );

      if (code.isNotEmpty) {
        setState(() {
          _pairing = true;
          _statusText = 'Verbinde...';
        });
        try {
          final api = ApiService(updated);
          final deviceModel = await _getDeviceModel();
          final result = await api.pairFull(code, deviceModel);
          if (!mounted) return;
          if (result == null) {
            _showError('Kopplungscode ungültig oder abgelaufen');
            setState(() {
              _pairing = false;
              _statusText = '';
            });
            return;
          }
          updated = updated.copyWith(
            deviceToken: result.token,
            macAddress: result.macAddress ?? updated.macAddress,
          );
        } catch (e) {
          if (!mounted) return;
          _showError('Verbindung fehlgeschlagen: $e');
          setState(() {
            _pairing = false;
            _statusText = '';
          });
          return;
        }
      }

      await storage.updateProfile(updated);
      if (!mounted) return;
      setState(() {
        _pairing = false;
        _statusText = '';
      });
      Navigator.of(context).pop(true);
    } else {
      // New device: discover agents on network, then pair
      if (code.isEmpty) {
        _showError('Bitte Kopplungscode eingeben');
        return;
      }

      setState(() {
        _pairing = true;
        _statusText = 'Suche Geräte im Netzwerk...';
      });

      try {
        final agents = await DiscoveryService.discover();
        if (!mounted) return;

        if (agents.isEmpty) {
          _showError(
              'Kein PC-Agent im Netzwerk gefunden. Ist der Agent gestartet?');
          setState(() {
            _pairing = false;
            _statusText = '';
          });
          return;
        }

        setState(() => _statusText = 'Versuche Kopplung...');

        final deviceModel = await _getDeviceModel();
        for (final agent in agents) {
          final result = await ApiService.pairWithHost(
            agent.ip,
            agent.port,
            code,
            deviceModel,
          );

          if (result != null) {
            final profileName =
                name.isEmpty ? (result.pcName ?? agent.name) : name;

            final profile = PcProfile(
              name: profileName,
              macAddress: result.macAddress ?? agent.mac,
              ipAddress: agent.ip,
              port: agent.port,
              deviceToken: result.token,
            );

            await storage.addProfile(profile);
            if (!mounted) return;
            Navigator.of(context).pop(true);
            return;
          }
        }

        if (!mounted) return;
        _showError('Kopplungscode ungültig oder abgelaufen');
      } catch (e) {
        if (!mounted) return;
        _showError('Fehler bei der Suche: $e');
      } finally {
        if (mounted) {
          setState(() {
            _pairing = false;
            _statusText = '';
          });
        }
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _isEditing ? 'Geräteeinstellungen' : 'Gerät hinzufügen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.computer, size: 64),
              const SizedBox(height: 24),

              // Name field (always editable)
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: _isEditing ? null : 'Mein PC',
                  prefixIcon: const Icon(Icons.label),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // In edit mode: show MAC, IP, Port as grayed out
              if (_isEditing) ...[
                TextFormField(
                  initialValue: widget.editProfile!.macAddress,
                  decoration: const InputDecoration(
                    labelText: 'MAC-Adresse',
                    prefixIcon: Icon(Icons.lan),
                    border: OutlineInputBorder(),
                  ),
                  enabled: false,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: widget.editProfile!.ipAddress,
                  decoration: const InputDecoration(
                    labelText: 'IP-Adresse',
                    prefixIcon: Icon(Icons.wifi),
                    border: OutlineInputBorder(),
                  ),
                  enabled: false,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: widget.editProfile!.port.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                  ),
                  enabled: false,
                ),
                const SizedBox(height: 16),
              ],

              const Divider(),
              const SizedBox(height: 8),
              Text(
                _isEditing
                    ? 'Erneut koppeln (optional)'
                    : 'Gerät koppeln',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                _isEditing
                    ? 'Nur ausfüllen, wenn du das Gerät neu koppeln möchtest.'
                    : 'Öffne die Web-Oberfläche auf deinem PC und generiere einen Kopplungscode.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Kopplungscode',
                  hintText: '000000',
                  prefixIcon: Icon(Icons.pin),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: _isEditing
                    ? null
                    : (v) => v == null || v.trim().isEmpty
                        ? 'Code eingeben'
                        : null,
              ),
              const SizedBox(height: 8),
              if (_statusText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _statusText,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _pairing ? null : _save,
                icon: _pairing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(_isEditing ? Icons.save : Icons.link),
                label: Text(_pairing
                    ? 'Verbinde...'
                    : _isEditing
                        ? 'Speichern'
                        : 'Verbinden'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
