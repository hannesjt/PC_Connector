import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../models/pc_profile.dart';
import '../models/script_config.dart';
import '../services/api_service.dart';
import '../services/pin_lock_service.dart';
import '../services/storage_service.dart';
import '../services/purchase_service.dart';
import '../services/wol_service.dart';
import '../widgets/status_indicator.dart';
import '../widgets/script_button.dart';
import 'clipboard_sheet.dart';
import 'file_explorer_screen.dart';
import 'history_screen.dart';
import 'input_control_screen.dart';
import 'paywall_sheet.dart';
import 'screen_view_screen.dart';
import 'volume_sheet.dart';

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

  // Script scope filter: false = dieses System, true = alle Systeme
  bool _showGlobalScripts = false;

  bool get _isPro => PurchaseService.instance.isPro;

  // Offline re-pairing
  final _offlinePairCodeCtrl = TextEditingController();
  bool _offlinePairing = false;

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
    _offlinePairCodeCtrl.dispose();
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
    final l = AppLocalizations.of(context);
    try {
      await _wol.sendWol(widget.profile.macAddress);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.wolSent)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.error(e))),
      );
    }
  }

  Future<void> _runScript(ScriptConfig script) async {
    final l = AppLocalizations.of(context);
    if (script.confirm) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.runScriptTitle(script.name)),
          content: Text(l.runScriptConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.run),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.scriptRunning(script.name))),
    );

    try {
      final result = await _api.runScript(script.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.scriptSuccess(script.name)),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorMsg = result.stderr.isNotEmpty
            ? result.stderr.trim().replaceAll('\r\n', ' ').replaceAll('\n', ' ')
            : l.exitCode(result.exitCode);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.scriptFailed(script.name)),
            content: SingleChildScrollView(child: Text(errorMsg)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l.ok),
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
          title: Text(l.connectionError),
          content: SingleChildScrollView(child: Text(msg)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.ok),
            ),
          ],
        ),
      );
    }
  }

  void _reorderScripts(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      // Map filtered indices → full _scripts indices
      final filteredItems = _filteredScripts;
      final movedItem = filteredItems[oldIndex];
      final targetItem = filteredItems[newIndex];
      final actualOld = _scripts.indexOf(movedItem);
      final actualNew = _scripts.indexOf(targetItem);
      _scripts.removeAt(actualOld);
      _scripts.insert(actualNew, movedItem);
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
    final l = AppLocalizations.of(context);
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
          title: Text(existingGroup != null ? l.editGroup : l.newGroup),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l.groupName),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                Text(l.scriptsLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: _scripts
                          .map((s) => CheckboxListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(s.name),
                                subtitle: s.group.isNotEmpty &&
                                        s.group != existingGroup
                                    ? Text(l.groupPrefix(s.group),
                                        style: const TextStyle(fontSize: 11))
                                    : null,
                                value: selected.contains(s.id),
                                onChanged: (v) => setDialogState(() {
                                  if (v == true)
                                    selected.add(s.id);
                                  else
                                    selected.remove(s.id);
                                }),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.save),
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
        SnackBar(content: Text(l.error(e))),
      );
    }
  }

  Future<void> _runChain(ScriptChain chain) async {
    final l = AppLocalizations.of(context);
    setState(() => _runningChains[chain.id] = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l.scriptRunning(chain.name))),
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
            content: Text(l.chainDone(chain.name)),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.chainFailedSteps(chain.name, failed)),
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
          title: Text(l.errorTitle),
          content: Text(msg),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.ok)),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _runningChains.remove(chain.id));
    }
  }

  List<ScriptConfig> get _filteredScripts {
    final all =
        _scripts.where((s) => s.isGlobal == _showGlobalScripts).toList();
    // Free tier: show max 3 scripts but keep all for display so user sees what's locked
    return all;
  }

  /// Returns true when the script at [index] in the filtered list is accessible.
  bool _scriptAccessible(int index) => _isPro || index < kFreeMaxScripts;

  Future<void> _pairFromHomeScreen() async {
    final l = AppLocalizations.of(context);
    final code = _offlinePairCodeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _offlinePairing = true);
    try {
      String deviceName = 'Mein Gerät';
      try {
        final info = await DeviceInfoPlugin().androidInfo;
        final brand = info.brand;
        final model = info.model;
        deviceName = model.toLowerCase().startsWith(brand.toLowerCase())
            ? model
            : '$brand $model';
      } catch (_) {}
      final result = await _api.pairFull(code, deviceName);
      if (!mounted) return;
      if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.pairCodeInvalidExpired),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final updated = widget.profile.copyWith(
        deviceToken: result.token,
        macAddress: result.macAddress ?? widget.profile.macAddress,
      );
      await StorageService().updateProfile(updated);
      _offlinePairCodeCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.pairedSuccess),
          backgroundColor: Colors.green,
        ),
      );
      _checkStatus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.connectionFailed(e))),
      );
    } finally {
      if (mounted) setState(() => _offlinePairing = false);
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

  void _showSettingsSheet() {
    final l = AppLocalizations.of(context);
    final appState = PcConnectorApp.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isDark = appState?.themeMode == ThemeMode.dark;
          final pinEnabled = PinLockService.instance.enabled;
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l.settings, style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(l.darkMode),
                  secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  value: isDark,
                  onChanged: (val) {
                    final mode = val ? ThemeMode.dark : ThemeMode.light;
                    appState?.setThemeMode(mode);
                    setSheetState(() {});
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l.language),
                  trailing: DropdownButton<String>(
                    value: appState?.locale?.languageCode ?? 'system',
                    underline: const SizedBox.shrink(),
                    onChanged: (val) {
                      final locale = val == 'system' ? null : Locale(val!);
                      appState?.setLocale(locale);
                      setSheetState(() {});
                    },
                    items: [
                      DropdownMenuItem(
                          value: 'system', child: Text(l.languageSystem)),
                      const DropdownMenuItem(
                          value: 'de', child: Text('Deutsch')),
                      const DropdownMenuItem(
                          value: 'en', child: Text('English')),
                    ],
                  ),
                ),
                SwitchListTile(
                  title: Text(l.pinLock),
                  secondary: const Icon(Icons.lock_outline),
                  subtitle: Text(pinEnabled ? l.active : l.inactive),
                  value: pinEnabled,
                  onChanged: (val) async {
                    if (val && !_isPro) {
                      Navigator.pop(ctx);
                      showPaywallSheet(context, reason: l.pinLockProReason);
                      return;
                    }
                    if (val) {
                      Navigator.pop(ctx);
                      _showSetPinDialog();
                    } else {
                      await PinLockService.instance.removePin();
                      setSheetState(() {});
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSetPinDialog() {
    final l = AppLocalizations.of(context);
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.setPin),
        content: TextField(
          controller: pinCtrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: InputDecoration(
            labelText: l.pinDigits,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final pin = pinCtrl.text.trim();
              if (pin.length != 4) return;
              await PinLockService.instance.setPin(pin);
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l.pinSet)),
              );
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
  }

  Widget _sortButton(VoidCallback onTap) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: onTap,
          tooltip: AppLocalizations.of(context).changeOrder,
        ),
        if (!_isPro)
          Positioned(
            right: 4,
            top: 4,
            child: Icon(Icons.lock,
                size: 12, color: Theme.of(context).colorScheme.outline),
          ),
      ],
    );
  }

  Widget _proButton({
    required bool isPro,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required String reason,
  }) {
    return Stack(
      children: [
        OutlinedButton.icon(
          onPressed:
              isPro ? onTap : () => showPaywallSheet(context, reason: reason),
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40),
          ),
        ),
        if (!isPro)
          Positioned(
            right: 4,
            top: 4,
            child: Icon(Icons.lock,
                size: 14, color: Theme.of(context).colorScheme.outline),
          ),
      ],
    );
  }

  Widget _buildScopeToggle(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text(l.thisSystem),
                icon: const Icon(Icons.computer),
              ),
              ButtonSegment(
                value: true,
                label: Text(l.allSystems),
                icon: const Icon(Icons.public),
              ),
            ],
            selected: {_showGlobalScripts},
            onSelectionChanged: (val) {
              if (val.first == true && !_isPro) {
                showPaywallSheet(context, reason: l.globalScriptsProReason);
                return;
              }
              setState(() {
                _showGlobalScripts = val.first;
                _reorderMode = false;
              });
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final filtered = _filteredScripts;
    final grouped = <String, List<ScriptConfig>>{};
    for (final s in filtered) {
      final g = s.group.isEmpty ? '' : s.group;
      grouped.putIfAbsent(g, () => []).add(s);
    }
    final orderedCats = _orderedCategories(grouped);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile.name),
        actions: [
          if (_isOnline && _activeSection == 0 && _scripts.isNotEmpty)
            _reorderMode
                ? TextButton(
                    onPressed: _saveScriptOrder,
                    child: Text(l.done),
                  )
                : _sortButton(() {
                    if (!_isPro) {
                      showPaywallSheet(context, reason: l.reorderProReason);
                      return;
                    }
                    setState(() => _reorderMode = true);
                  }),
          if (_isOnline && _activeSection == 1 && _chains.isNotEmpty)
            _reorderMode
                ? TextButton(
                    onPressed: _saveChainOrder,
                    child: Text(l.done),
                  )
                : _sortButton(() {
                    if (!_isPro) {
                      showPaywallSheet(context, reason: l.reorderProReason);
                      return;
                    }
                    setState(() => _reorderMode = true);
                  }),
          if (_isOnline && _activeSection == 2) ...[
            if (_reorderMode && _categoryOrder.isNotEmpty)
              TextButton(
                onPressed: _saveCategoryOrder,
                child: Text(l.done),
              )
            else
              IconButton(
                icon: const Icon(Icons.create_new_folder_outlined),
                onPressed: () => _showGroupDialog(),
                tooltip: l.newGroup,
              ),
            if (!_reorderMode && _categoryOrder.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.sort),
                onPressed: () => setState(() => _reorderMode = true),
                tooltip: l.changeOrder,
              ),
          ],
          if (!_reorderMode)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _checking
                  ? null
                  : () async {
                      setState(() => _checking = true);
                      await _checkStatus();
                      if (_isOnline) await _loadScripts();
                    },
              tooltip: l.refreshStatus,
            ),
          if (!_isPro)
            IconButton(
              icon: const Icon(Icons.workspace_premium),
              onPressed: () =>
                  showPaywallSheet(context, reason: l.upgradeProReason),
              tooltip: l.buyPro,
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
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                widget.profile.ipAddress,
                                style: Theme.of(context).textTheme.bodySmall,
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
              label: Text(l.wakeOnLan),
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
                    l.wolHint,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Input control button (only when online)
            if (_isOnline) ...[
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InputControlScreen(api: _api),
                  ),
                ),
                icon: const Icon(Icons.mouse),
                label: Text(l.mouseKeyboard),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 8),
              // Feature buttons row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showVolumeSheet(context, _api),
                      icon: const Icon(Icons.volume_up, size: 18),
                      label: Text(l.volume),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showClipboardSheet(context, _api),
                      icon: const Icon(Icons.content_paste, size: 18),
                      label: Text(l.clipboard),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _proButton(
                      isPro: _isPro,
                      icon: Icons.screenshot_monitor,
                      label: l.screen,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ScreenViewScreen(api: _api))),
                      reason: l.screenProReason,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _proButton(
                      isPro: _isPro,
                      icon: Icons.folder_open,
                      label: l.files,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => FileExplorerScreen(api: _api))),
                      reason: l.filesProReason,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _proButton(
                      isPro: _isPro,
                      icon: Icons.history,
                      label: l.history,
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => HistoryScreen(api: _api))),
                      reason: l.historyProReason,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _showSettingsSheet,
                      icon: const Icon(Icons.settings, size: 18),
                      label: Text(l.settings),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            const SizedBox(height: 16),

            // Script/Chain/Category section header
            if (_isOnline) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final entry in [
                    (0, l.scripts),
                    (1, l.chains),
                    (2, l.categories),
                  ])
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Ablu00e4ufe (1) und Kategorien (2) sind Pro-Features
                          if (entry.$1 != 0 && !_isPro) {
                            showPaywallSheet(context,
                                reason: l.sectionProReason(entry.$2));
                            return;
                          }
                          setState(() {
                            _activeSection = entry.$1;
                            _reorderMode = false;
                            _selectedCategory = null;
                          });
                        },
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
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
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
            if (_isOnline &&
                _activeSection == 0 &&
                _reorderMode &&
                _scripts.isNotEmpty) ...[
              // Scope toggle in reorder mode too
              _buildScopeToggle(context),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l.dragToReorder,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                onReorder: _reorderScripts,
                itemBuilder: (context, index) {
                  final script = filtered[index];
                  return ListTile(
                    key: ValueKey(script.id),
                    leading: const Icon(Icons.drag_handle),
                    title: Text(script.name),
                    trailing:
                        const Icon(Icons.drag_indicator, color: Colors.grey),
                  );
                },
              ),

              // Scripts – normal mode
            ] else if (_isOnline &&
                _activeSection == 0 &&
                !_reorderMode &&
                _scripts.isNotEmpty) ...[
              _buildScopeToggle(context),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.8,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final script = filtered[index];
                  final accessible = _scriptAccessible(index);
                  return Stack(
                    children: [
                      ScriptButton(
                        script: script,
                        onPressed: accessible
                            ? () => _runScript(script)
                            : () => showPaywallSheet(context,
                                reason: l.unlimitedScriptsReason),
                      ),
                      if (!accessible)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.lock,
                                  color: Colors.white70, size: 28),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      _showGlobalScripts
                          ? l.noGlobalScripts
                          : l.noSystemScripts,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
            ] else if (_isOnline &&
                _activeSection == 0 &&
                !_reorderMode &&
                _scripts.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(l.noScriptsConfigured),
                ),
              ),

              // Chains – reorder mode
            ] else if (_isOnline &&
                _activeSection == 1 &&
                _reorderMode &&
                _chains.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l.dragToReorder,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
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
                    subtitle: Text(l.stepCount(chain.steps.length)),
                    trailing:
                        const Icon(Icons.drag_indicator, color: Colors.grey),
                  );
                },
              ),

              // Chains – normal mode
            ] else if (_isOnline &&
                _activeSection == 1 &&
                !_reorderMode &&
                _chains.isNotEmpty) ...[
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
            ] else if (_isOnline &&
                _activeSection == 1 &&
                !_reorderMode &&
                _chains.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(l.noChainsConfigured),
                ),
              ),

              // Kategorien
            ] else if (_isOnline && _activeSection == 2) ...[
              Builder(builder: (ctx) {
                if (orderedCats.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l.noCategoriesConfigured,
                      ),
                    ),
                  );
                }
                if (_reorderMode) {
                  return ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    header: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        l.dragToReorder,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
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
                          l.scriptCount(grouped[group]?.length ?? 0),
                        ),
                        trailing: const Icon(Icons.drag_indicator,
                            color: Colors.grey),
                      );
                    },
                  );
                }
                final catCards = orderedCats.map((group) {
                  return InkWell(
                    key: ValueKey(group),
                    onTap: () => setState(() {
                      _selectedCategory =
                          _selectedCategory == group ? null : group;
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
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
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
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    l.scriptCount(grouped[group]!.length),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () =>
                                  _showGroupDialog(existingGroup: group),
                              tooltip: l.edit,
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
                    if (_selectedCategory != null &&
                        grouped[_selectedCategory] != null) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _selectedCategory!.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                        ),
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(l.pcOffline),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.repair,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.repairCodeHint,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _offlinePairCodeCtrl,
                        decoration: InputDecoration(
                          labelText: l.pairCode,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.vpn_key_outlined),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: !_offlinePairing,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _offlinePairing ? null : _pairFromHomeScreen,
                        icon: _offlinePairing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.link),
                        label: Text(_offlinePairing ? l.connecting : l.pair),
                      ),
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
