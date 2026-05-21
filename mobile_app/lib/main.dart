import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/device_list_screen.dart';
import 'services/pin_lock_service.dart';
import 'services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PurchaseService.instance.init();
  await PinLockService.instance.init();
  runApp(const PcConnectorApp());
}

class PcConnectorApp extends StatefulWidget {
  const PcConnectorApp({super.key});

  static _PcConnectorAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_PcConnectorAppState>();

  @override
  State<PcConnectorApp> createState() => _PcConnectorAppState();
}

class _PcConnectorAppState extends State<PcConnectorApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_mode') ?? 'dark';
    setState(() {
      _themeMode = mode == 'light' ? ThemeMode.light : ThemeMode.dark;
    });
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'theme_mode', mode == ThemeMode.light ? 'light' : 'dark');
  }

  ThemeMode get themeMode => _themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PC Connector',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: PinLockService.instance.enabled && !_unlocked
          ? PinLockScreen(onUnlocked: () => setState(() => _unlocked = true))
          : const DeviceListScreen(),
    );
  }
}
