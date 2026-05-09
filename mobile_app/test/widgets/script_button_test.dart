import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pc_connector/models/script_config.dart';
import 'package:pc_connector/widgets/script_button.dart';

void main() {
  group('ScriptButton', () {
    testWidgets('displays script name', (tester) async {
      const script = ScriptConfig(
        id: 'test',
        name: 'Test Script',
        icon: 'play_arrow',
        confirm: false,
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ScriptButton(script: script, onPressed: () {}),
        ),
      ));
      expect(find.text('Test Script'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;
      const script = ScriptConfig(
        id: 'test',
        name: 'Tap Me',
        icon: 'play_arrow',
        confirm: false,
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ScriptButton(script: script, onPressed: () => tapped = true),
        ),
      ));
      await tester.tap(find.text('Tap Me'));
      expect(tapped, true);
    });

    testWidgets('shows correct icon for power_off', (tester) async {
      const script = ScriptConfig(
        id: 'off',
        name: 'Power Off',
        icon: 'power_off',
        confirm: false,
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ScriptButton(script: script, onPressed: () {}),
        ),
      ));
      expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
    });

    testWidgets('uses fallback icon for unknown name', (tester) async {
      const script = ScriptConfig(
        id: 'x',
        name: 'X',
        icon: 'unknown_icon_xyz',
        confirm: false,
      );
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ScriptButton(script: script, onPressed: () {}),
        ),
      ));
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
  });
}
