import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';

class InputControlScreen extends StatefulWidget {
  final ApiService api;

  const InputControlScreen({super.key, required this.api});

  @override
  State<InputControlScreen> createState() => _InputControlScreenState();
}

class _InputControlScreenState extends State<InputControlScreen> {
  // Sensitivity multiplier for the touchpad
  static const double _sensitivity = 3.6;

  // Invisible sentinel keeps the field non-empty so backspace always fires onChanged
  static const String _sentinel = '\u200b';

  // Throttle: minimum ms between move requests
  static const int _moveThrottleMs = 16; // ~60 fps

  bool _resettingSentinel = false;

  DateTime _lastMoveSent = DateTime.fromMillisecondsSinceEpoch(0);
  double _pendingDx = 0;
  double _pendingDy = 0;
  Timer? _moveFlushTimer;

  // Scroll accumulator
  double _scrollAccumY = 0;
  double _scrollAccumX = 0;
  static const double _scrollStepThreshold = 0.25;

  // Keyboard
  final TextEditingController _typeController =
      TextEditingController(text: '\u200b');
  final FocusNode _typeFocus = FocusNode();
  String _lastText = '';

  @override
  void dispose() {
    _moveFlushTimer?.cancel();
    _typeController.dispose();
    _typeFocus.dispose();
    super.dispose();
  }

  // ---- Mouse movement (touchpad) ----

  void _onPanUpdate(DragUpdateDetails details) {
    _pendingDx += details.delta.dx * _sensitivity;
    _pendingDy += details.delta.dy * _sensitivity;

    final now = DateTime.now();
    final elapsed = now.difference(_lastMoveSent).inMilliseconds;
    if (elapsed >= _moveThrottleMs) {
      _flushMove();
    } else {
      _moveFlushTimer?.cancel();
      _moveFlushTimer = Timer(
        Duration(milliseconds: _moveThrottleMs - elapsed),
        _flushMove,
      );
    }
  }

  void _flushMove() {
    if (_pendingDx == 0 && _pendingDy == 0) return;
    final dx = _pendingDx;
    final dy = _pendingDy;
    _pendingDx = 0;
    _pendingDy = 0;
    _lastMoveSent = DateTime.now();
    widget.api.mouseMoveRel(dx, dy).ignore();
  }

  // ---- Scroll (dedicated scroll pad) ----

  void _onScrollPanUpdate(DragUpdateDetails details) {
    _scrollAccumY += details.delta.dy;
    _scrollAccumX += details.delta.dx;

    if (_scrollAccumY.abs() >= _scrollStepThreshold) {
      final steps = (_scrollAccumY / _scrollStepThreshold).round();
      // Invert: dragging down → scroll down (negative pyautogui scroll)
      widget.api.mouseScroll(dy: (-steps).toDouble()).ignore();
      _scrollAccumY -= steps * _scrollStepThreshold;
    }
    if (_scrollAccumX.abs() >= _scrollStepThreshold) {
      final steps = (_scrollAccumX / _scrollStepThreshold).round();
      widget.api.mouseScroll(dx: steps.toDouble()).ignore();
      _scrollAccumX -= steps * _scrollStepThreshold;
    }
  }

  // ---- Keyboard ----

  void _openKeyboard() {
    _resettingSentinel = true;
    _typeController.value = TextEditingValue(
      text: _sentinel,
      selection: TextSelection.collapsed(offset: _sentinel.length),
    );
    _resettingSentinel = false;
    _lastText = '';
    _typeFocus.requestFocus();
  }

  void _onTextChanged(String value) {
    if (_resettingSentinel) return;

    final sentinelConsumed = !value.contains(_sentinel);
    final effective = value.replaceAll(_sentinel, '');

    if (effective.length > _lastText.length) {
      // Characters added
      final added = effective.substring(_lastText.length);
      widget.api.keyboardType(added).ignore();
    } else if (effective.length < _lastText.length) {
      // Visible text was deleted (backspace on non-empty field)
      final deleted = _lastText.length - effective.length;
      for (var i = 0; i < deleted; i++) {
        widget.api.keyboardKey('backspace').ignore();
      }
    } else if (sentinelConsumed) {
      // No visible text changed but sentinel was eaten → backspace on empty field
      widget.api.keyboardKey('backspace').ignore();
    }

    _lastText = effective;

    // Restore sentinel whenever it was consumed
    if (sentinelConsumed) {
      _resettingSentinel = true;
      _typeController.value = TextEditingValue(
        text: _sentinel,
        selection: TextSelection.collapsed(offset: _sentinel.length),
      );
      _resettingSentinel = false;
    }
  }

  Widget _buildSpecialKeyButton(String label, String key, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: OutlinedButton(
        onPressed: () => widget.api.keyboardKey(key).ignore(),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: icon != null
            ? Icon(icon, size: 18)
            : Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.mouseKeyboard),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ---- Touchpad area ----
            Expanded(
              flex: 5,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: _onPanUpdate,
                onTap: () => widget.api.mouseClick(button: 'left').ignore(),
                onDoubleTap: () => widget.api
                    .mouseClick(button: 'left', double_: true)
                    .ignore(),
                onSecondaryTap: () =>
                    widget.api.mouseClick(button: 'right').ignore(),
                onLongPress: () =>
                    widget.api.mouseClick(button: 'right').ignore(),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 40,
                          color: colorScheme.onSurfaceVariant.withAlpha(100),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.touchpad,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant.withAlpha(140),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          l.touchpadHint,
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant.withAlpha(100),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ---- Mouse buttons ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: _MouseButton(
                      label: l.left,
                      icon: Icons.mouse,
                      onTap: () =>
                          widget.api.mouseClick(button: 'left').ignore(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Scroll pad (narrow column between mouse buttons)
                  SizedBox(
                    width: 60,
                    height: 56,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: _onScrollPanUpdate,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.unfold_more,
                                size: 22, color: colorScheme.onSurfaceVariant),
                            Text(
                              l.scroll,
                              style: TextStyle(
                                fontSize: 9,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MouseButton(
                      label: l.right,
                      icon: Icons.mouse,
                      onTap: () =>
                          widget.api.mouseClick(button: 'right').ignore(),
                      iconMirror: true,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 16, indent: 12, endIndent: 12),

            // ---- Special keys ----
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _buildSpecialKeyButton('Esc', 'escape'),
                  _buildSpecialKeyButton('Tab', 'tab'),
                  _buildSpecialKeyButton('Win', 'win',
                      icon: Icons.window_outlined),
                  _buildSpecialKeyButton('Del', 'delete'),
                  _buildSpecialKeyButton('Home', 'home'),
                  _buildSpecialKeyButton('End', 'end'),
                  _buildSpecialKeyButton('PgUp', 'pageup'),
                  _buildSpecialKeyButton('PgDn', 'pagedown'),
                  _buildSpecialKeyButton('', 'up', icon: Icons.arrow_upward),
                  _buildSpecialKeyButton('', 'down',
                      icon: Icons.arrow_downward),
                  _buildSpecialKeyButton('', 'left', icon: Icons.arrow_back),
                  _buildSpecialKeyButton('', 'right',
                      icon: Icons.arrow_forward),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ---- Keyboard input ----
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _typeController,
                          focusNode: _typeFocus,
                          onChanged: _onTextChanged,
                          onSubmitted: (_) {
                            widget.api.keyboardKey('enter').ignore();
                            _resettingSentinel = true;
                            _typeController.value = TextEditingValue(
                              text: _sentinel,
                              selection: TextSelection.collapsed(
                                  offset: _sentinel.length),
                            );
                            _resettingSentinel = false;
                            _lastText = '';
                            _typeFocus.requestFocus();
                          },
                          decoration: InputDecoration(
                            hintText: l.typeText,
                            prefixIcon: const Icon(Icons.keyboard),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.send),
                              tooltip: 'Enter',
                              onPressed: () {
                                widget.api.keyboardKey('enter').ignore();
                                _typeController.clear();
                                _lastText = '';
                                _typeFocus.requestFocus();
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MouseButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool iconMirror;

  const _MouseButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.iconMirror = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!iconMirror) ...[
                Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (iconMirror) ...[
                const SizedBox(width: 6),
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(-1.0, 1.0),
                  child:
                      Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
