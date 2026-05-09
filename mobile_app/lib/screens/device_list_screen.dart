import 'package:flutter/material.dart';
import '../models/pc_profile.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';
import 'setup_screen.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  final _storage = StorageService();
  List<PcProfile> _profiles = [];
  final Map<String, bool> _onlineStatus = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final profiles = await _storage.loadProfiles();
    if (!mounted) return;
    setState(() {
      _profiles = profiles;
      _loading = false;
    });
    _checkAllStatus();
  }

  Future<void> _checkAllStatus() async {
    for (final profile in _profiles) {
      final api = ApiService(profile);
      final online = await api.isOnline();
      if (!mounted) return;
      if (online) {
        // Update lastSeen timestamp
        final updated = profile.copyWith(lastSeen: DateTime.now());
        await _storage.updateProfile(updated);
        final idx = _profiles.indexWhere((p) => p.id == profile.id);
        if (idx >= 0) _profiles[idx] = updated;
      }
      setState(() => _onlineStatus[profile.id] = online);
    }
  }

  void _openDevice(PcProfile profile) {
    if (!profile.isPaired) {
      _editDevice(profile);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => HomeScreen(profile: profile)),
    );
  }

  void _addDevice() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SetupScreen()),
    );
    if (result == true) _loadProfiles();
  }

  void _editDevice(PcProfile profile) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SetupScreen(editProfile: profile)),
    );
    if (result == true) _loadProfiles();
  }

  void _deleteDevice(PcProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gerät entfernen?'),
        content: Text('Möchtest du "${profile.name}" wirklich entfernen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _storage.deleteProfile(profile.id);
      _loadProfiles();
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    setState(() {
      final item = _profiles.removeAt(oldIndex);
      _profiles.insert(newIndex, item);
    });
    await _storage.saveProfiles(_profiles);
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Noch nie gesehen';
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    if (diff.inMinutes < 1) return 'Gerade eben online';
    if (diff.inMinutes < 60) return 'Vor ${diff.inMinutes} Min. online';
    if (diff.inHours < 24) return 'Vor ${diff.inHours} Std. online';
    return 'Vor ${diff.inDays} Tag(en) online';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PC Connector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _onlineStatus.clear();
              _checkAllStatus();
            },
            tooltip: 'Status aktualisieren',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDevice,
        icon: const Icon(Icons.add),
        label: const Text('Gerät hinzufügen'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.devices, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Keine Geräte konfiguriert.'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _addDevice,
                        icon: const Icon(Icons.add),
                        label: const Text('Gerät hinzufügen'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfiles,
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _profiles.length,
                    onReorder: _onReorder,
                    itemBuilder: (context, index) {
                      final profile = _profiles[index];
                      final isOnline = _onlineStatus[profile.id];
                      return _DeviceCard(
                        key: ValueKey(profile.id),
                        profile: profile,
                        isOnline: isOnline,
                        lastSeenText: _formatLastSeen(profile.lastSeen),
                        onTap: () => _openDevice(profile),
                        onEdit: () => _editDevice(profile),
                        onDelete: () => _deleteDevice(profile),
                      );
                    },
                  ),
                ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final PcProfile profile;
  final bool? isOnline;
  final String lastSeenText;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DeviceCard({
    super.key,
    required this.profile,
    required this.isOnline,
    required this.lastSeenText,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.computer, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.ipAddress,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    if (!profile.isPaired)
                      Text(
                        'Nicht gekoppelt',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.orange,
                            ),
                      )
                    else
                      Text(
                        lastSeenText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                  ],
                ),
              ),
              // Status
              if (isOnline == null)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline! ? Colors.green : Colors.red,
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: onEdit,
                tooltip: 'Einstellungen',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                tooltip: 'Entfernen',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
