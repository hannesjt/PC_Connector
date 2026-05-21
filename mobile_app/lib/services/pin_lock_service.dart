import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinLockService {
  PinLockService._();
  static final instance = PinLockService._();

  String? _pin;
  bool _enabled = false;

  bool get enabled => _enabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _pin = prefs.getString('app_pin');
    _enabled = _pin != null && _pin!.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_pin', pin);
    _pin = pin;
    _enabled = true;
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('app_pin');
    _pin = null;
    _enabled = false;
  }

  bool verify(String input) => input == _pin;
}

class PinLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const PinLockScreen({super.key, required this.onUnlocked});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _input = '';
  String? _error;

  void _addDigit(String d) {
    if (_input.length >= 6) return;
    setState(() {
      _input += d;
      _error = null;
    });
    if (_input.length == 4) _tryUnlock();
  }

  void _backspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _tryUnlock() {
    if (PinLockService.instance.verify(_input)) {
      widget.onUnlocked();
    } else {
      setState(() {
        _error = 'Falsche PIN';
        _input = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 48),
              const SizedBox(height: 16),
              Text('PIN eingeben', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  return Container(
                    width: 16, height: 16,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _input.length
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  );
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 32),
              _buildNumpad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    // Standard phone layout: 1-2-3 / 4-5-6 / 7-8-9 / ⌫-0-OK
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows.map((row) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: row.map((k) {
          if (k.isEmpty) return const SizedBox(width: 72, height: 72);
          return SizedBox(
            width: 72, height: 72,
            child: TextButton(
              onPressed: k == '⌫' ? _backspace : () => _addDigit(k),
              child: Text(
                k,
                style: TextStyle(
                  fontSize: k == '⌫' ? 20 : 26,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      )).toList(),
    );
  }
}
