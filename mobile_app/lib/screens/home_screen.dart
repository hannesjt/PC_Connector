import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pc_profile.dart';
import '../models/script_config.dart';
import '../services/api_service.dart';
import '../services/wol_service.dart';
import '../widgets/status_indicator.dart';
import '../widgets/script_button.dart';

class HomeScreen extends StatefulWidget {
  final PcProfile profile;

  const HomeScreen({super.key, required this.profile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ApiService _api;
  final _wol = WolService();

  bool _isOnline = false;
  bool _checking = true;
  List<ScriptConfig> _scripts = [];
  List<ScriptChain> _chains = [];
  List<String> _categoryOrder = [];
  int _activeSection = 0; // 0=Skripte, 1=Abläufe, 2=Kategorien
  bool _reorderMode = false;
  String? _selectedCategory;
  final Map<String, bool> _runningChains = {};
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _api = ApiService(widget.profile);
    _checkStatus();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkStatus(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final online = await _api.isOnline();
    if (!mounted) return;
    setState(() {
      _isOnline = online;
      _checking = false;
    });
    if (online && _scripts.isEmpty) {
      _loadScripts();
    }
  }

  Future<void> _loadScripts() async {
    try {
      final scripts = await _api.getScripts();
      final chains = await _api.getChains();
      List<String> catOrder = [];
      try {
        final cats = await _api.getCategories();
        catOrder = cats;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _scripts = scripts;
        _chains = chains;
        _categoryOrder = catOrder;
      });
    } catch (_) {}
  }

  Future<void> _sendWol() async {
    try {
      await _wol.sendWol(widget.profile.macAddress);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wake-on-LAN Paket gesendet!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }

  Future<void> _runScript(ScriptConfig script) async {
    if (script.confirm) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${script.name} ausführen?'),
          content:
              const Text('Möchtest du dieses Skript wirklich ausführen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ausführen'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${script.name} wird ausgeführt...')),
    );

    try {
      final result = await _api.runScript(script.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${script.name} erfolgreich ausgeführt'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorMsg = result.stderr.isNotEmpty
            ? result.stderr.trim().replaceAll('\r\n', ' ').replaceAll('\n', ' ')
            : 'Exit-Code ${result.exitCode}';
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('${script.name} fehlgeschlagen'),
            content: SingleChildScrollView(child: Text(errorMsg)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      final msg = e.toString().replaceFirst('Exception: ', '');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Verbindungsfehler'),
          content: SingleChildScrollView(child: Text(msg)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _reorderScripts(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _scripts.removeAt(oldIndex);
      _scripts.insert(newIndex, item);
    });
  }

  Future<void> _saveScriptOrder() async {
    try {
      await _api.reorderScripts(_scripts.map((s) => s.id).toList());
    } catch (_) {}
    setState(() => _reorderMode = false);
  }

  void _reorderChains(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _chains.removeAt(oldIndex);
      _chains.insert(newIndex, item);
    });
  }

  Future<void> _saveChainOrder() async {
    try {
      await _api.reorderChains(_chains.map((c) => c.id).toList());
    } catch (_) {}
    setState(() => _reorderMode = false);
  }

  void _reorderCategories(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _categoryOrder.removeAt(oldIndex);
      _categoryOrder.insert(newIndex, item);
    });
  }

  Future<void> _saveCategoryOrder() async {
    try {
      await _api.reorderCategories(_categoryOrder);
    } catch (_) {}
    setState(() => _reorderMode = false);
  }

  Future<void> _showGroupDialog({String? existingGroup}) async {
    final nameController = TextEditingController(text: existingGroup ?? '');
    final selected = <String>{};
    if (existingGroup != null) {
      selected.addAll(
        _scripts.where((s) => s.group == existingGroup).map((s) => s.id),
      );
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existingGroup != null ? 'Gruppe bearbeiten' : 'Neue Gruppe'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Gruppenname'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                const Text('Skripte:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: _scripts.map((s) => CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.name),
                        subtitle: s.group.isNotEmpty && s.group != existingGroup
                            ? Text('Gruppe: ${s.group}', style: const TextStyle(fontSize: 11))
                            : null,
                        value: selected.contains(s.id),
                        onChanged: (v) => setDialogState(() {
                          if (v == true) selected.add(s.id);
                          else selected.remove(s.id);
                        }),
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    final groupName = nameController.text.trim();
    if (groupName.isEmpty) return;
    try {
      await _api.assignGroup(
        groupName,
        selected.toList(),
        oldGroup: existingGroup,
      );
      await _loadScripts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    }
  }

  Future<void> _runChain(ScriptChain chain) async {
    setState(() => _runningChains[chain.id] = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${chain.name} wird ausgeführt...')),
    );
    try {
      final result = await _api.runChain(chain.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      final results = result['results'] as List<dynamic>;
      final failed = results.where((r) => r['success'] == false).length;
      if (failed == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${chain.name} abgeschlossen'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${chain.name}: $failed Schritt(e) fehlgeschlagen'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      final msg = e.toString().replaceFirst('Exception: ', '');
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Fehler'),
          content: Text(msg),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _runningChains.remove(chain.id));
    }
  }

  Map<String, List<ScriptConfig>> get _groupedScripts {
    final groups = <String, List<ScriptConfig>>{};
    for (final s in _scripts) {
      final g = s.group.isEmpty ? '' : s.group;
      groups.putIfAbsent(g, () => []).add(s);
    }
    return groups;
  }

  /// Returns category names in the correct order (server order + unknown appended).
  List<String> _orderedCategories(Map<String, List<ScriptConfig>> grouped) {
    final available = grouped.keys.where((k) => k.isNotEmpty).toSet();
    final known = _categoryOrder.where((c) => available.contains(c)).toList();
    final rest = available.where((c) => !_categoryOrder.contains(c)).toList();
    return known + rest;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedScripts;
    final orderedCats = _orderedCategories(grouped);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.name),
        actions: [
          if (_isOnline && _activeSection == 0 && _scripts.isNotEmpty)
            _reorderMode
                ? TextButton(
                    onPressed: _saveScriptOrder,
                    child: const Text('Fertig'),
                  )
                : IconButton(
                    icon: const Icon(Icons.sort),
                    onPressed: () => setState(() => _reorderMode = true),
                    tooltip: 'Reihenfolge ändern',
                  ),
          if (_isOnline && _activeSection == 1 && _chains.isNotEmpty)
            _reorderMode
                ? TextButton(
                    onPressed: _saveChainOrder,
                    child: const Text('Fertig'),
                  )
                : IconButton(
                    icon: const Icon(Icons.sort),
                    onPressed: () => setState(() => _reorderMode = true),
                    tooltip: 'Reihenfolge ändern',
                  ),
          if (_isOnline && _activeSection == 2) ...[
            if (_reorderMode && _categoryOrder.isNotEmpty)
              TextButton(
                onPressed: _saveCategoryOrder,
                child: const Text('Fertig'),
              )
            else
              IconButton(
                icon: const Icon(Icons.create_new_folder_outlined),
                onPressed: () => _showGroupDialog(),
                tooltip: 'Neue Gruppe',
              ),
            if (!_reorderMode && _categoryOrder.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: () => setState(() => _reorderMode = true),
                tooltip: 'Reihenfolge ändern',
              ),
          ],
          if (!_reorderMode)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _checking ? null : () async {
                setState(() => _checking = true);
                await _checkStatus();
                if (_isOnline) await _loadScripts();
              },
              tooltip: 'Status aktualisieren',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _checkStatus();
          if (_isOnline) await _loadScripts();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // PC Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.computer, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.profile.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge,
                              ),
                              Text(
                                widget.profile.ipAddress,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                              ),
                            ],
                          ),
                        ),
                        StatusIndicator(
                          isOnline: _isOnline,
                          isChecking: _checking,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // WOL Button
            FilledButton.icon(
              onPressed: _sendWol,
              icon: const Icon(Icons.power_settings_new),
              label: const Text('Wake on LAN'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Wake-on-LAN muss im BIOS und in den Netzwerkadaptereinstellungen des PCs aktiviert sein.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Script/Chain/Category section header
            if (_isOnline) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final entry in [
                    (0, 'Skripte'),
                    (1, 'Abläufe'),
                    (2, 'Kategorien'),
                  ])
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _activeSection = entry.$1;
                          _reorderMode = false;
                          _selectedCategory = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _activeSection == entry.$1
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            entry.$2,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: _activeSection == entry.$1
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey,
                                  fontWeight: _activeSection == entry.$1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Scripts – reorder mode
            if (_isOnline && _activeSection == 0 && _reorderMode && _scripts.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Zum Umsortieren ziehen',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _scripts.length,
                onReorder: _reorderScripts,
                itemBuilder: (context, index) {
                  final script = _scripts[index];
                  return ListTile(
                    key: ValueKey(script.id),
                    leading: const Icon(Icons.drag_handle),
                    title: Text(script.name),
                    trailing: const Icon(Icons.drag_indicator, color: Colors.grey),
                  );
                },
              ),

            // Scripts – normal mode
            ] else if (_isOnline && _activeSection == 0 && !_reorderMode && _scripts.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                itemCount: _scripts.length,
                itemBuilder: (context, index) {
                  final script = _scripts[index];
                  return ScriptButton(
                    script: script,
                    onPressed: () => _runScript(script),
                  );
                },
              ),
              const SizedBox(height: 8),
            ] else if (_isOnline && _activeSection == 0 && !_reorderMode && _scripts.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Keine Skripte konfiguriert.'),
                ),
              ),

            // Chains – reorder mode
            ] else if (_isOnline && _activeSection == 1 && _reorderMode && _chains.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Zum Umsortieren ziehen',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _chains.length,
                onReorder: _reorderChains,
                itemBuilder: (context, index) {
                  final chain = _chains[index];
                  return ListTile(
                    key: ValueKey(chain.id),
                    leading: const Icon(Icons.drag_handle),
                    title: Text(chain.name),
                    subtitle: Text('${chain.steps.length} Schritt${chain.steps.length == 1 ? "" : "e"}'),
                    trailing: const Icon(Icons.drag_indicator, color: Colors.grey),
                  );
                },
              ),

            // Chains – normal mode
            ] else if (_isOnline && _activeSection == 1 && !_reorderMode && _chains.isNotEmpty) ...[
              for (final chain in _chains)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.account_tree_outlined),
                    title: Text(chain.name),
                    subtitle: Text(
                      chain.steps.map((s) {
                        final script = _scripts.firstWhere(
                          (sc) => sc.id == s.scriptId,
                          orElse: () => ScriptConfig(
                            id: s.scriptId,
                            name: s.scriptId,
                            icon: 'play_arrow',
                            confirm: false,
                          ),
                        );
                        return s.delaySeconds > 0
                            ? '${script.name} (+${s.delaySeconds}s)'
                            : script.name;
                      }).join(' → '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: _runningChains[chain.id] == true
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.play_circle_outline),
                            onPressed: () => _runChain(chain),
                          ),
                  ),
                ),
            ] else if (_isOnline && _activeSection == 1 && !_reorderMode && _chains.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Keine Abläufe konfiguriert.'),
                ),
              ),

            // Kategorien
            ] else if (_isOnline && _activeSection == 2) ...[
              Builder(builder: (ctx) {
                if (orderedCats.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'Keine Kategorien konfiguriert.\nGruppen können in der Web-Oberfläche vergeben werden.',
                      ),
                    ),
                  );
                }
                if (_reorderMode) {
                  return ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    header: const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Zum Umsortieren ziehen',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    itemCount: orderedCats.length,
                    onReorder: _reorderCategories,
                    itemBuilder: (ctx2, index) {
                      final group = orderedCats[index];
                      return ListTile(
                        key: ValueKey(group),
                        leading: const Icon(Icons.drag_handle),
                        title: Text(group),
                        subtitle: Text(
                          '${grouped[group]?.length ?? 0} Skript${(grouped[group]?.length ?? 0) == 1 ? "" : "e"}',
                        ),
                        trailing: const Icon(Icons.drag_indicator, color: Colors.grey),
                      );
                    },
                  );
                }
                final catCards = orderedCats.map((group) {
                  return InkWell(
                    key: ValueKey(group),
                    onTap: () => setState(() {
                      _selectedCategory = _selectedCategory == group ? null : group;
                    }),
                    onLongPress: () => _showGroupDialog(existingGroup: group),
                    borderRadius: BorderRadius.circular(12),
                    child: Card(
                      color: _selectedCategory == group
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              color: _selectedCategory == group
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    group,
                                    style: Theme.of(context).textTheme.titleSmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${grouped[group]!.length} Skript${grouped[group]!.length == 1 ? "" : "e"}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showGroupDialog(existingGroup: group),
                              tooltip: 'Bearbeiten',
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.2,
                      children: catCards,
                    ),
                    if (_selectedCategory != null && grouped[_selectedCategory] != null) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _selectedCategory!.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.6,
                        ),
                        itemCount: grouped[_selectedCategory]!.length,
                        itemBuilder: (ctx2, index) {
                          final script = grouped[_selectedCategory]![index];
                          return ScriptButton(
                            script: script,
                            onPressed: () => _runScript(script),
                          );
                        },
                      ),
                    ],
                  ],
                );
              }),
            ] else if (!_isOnline && !_checking) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('PC ist offline. Sende Wake-on-LAN zum Starten.'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

