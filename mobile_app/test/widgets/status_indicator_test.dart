import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pc_connector/widgets/status_indicator.dart';

void main() {
  group('StatusIndicator', () {
    testWidgets('shows Online when isOnline=true', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StatusIndicator(isOnline: true),
        ),
      ));
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Offline'), findsNothing);
    });

    testWidgets('shows Offline when isOnline=false', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StatusIndicator(isOnline: false),
        ),
      ));
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Online'), findsNothing);
    });

    testWidgets('shows spinner when checking', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StatusIndicator(isOnline: false, isChecking: true),
        ),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Online'), findsNothing);
      expect(find.text('Offline'), findsNothing);
    });

    testWidgets('shows green dot when online', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StatusIndicator(isOnline: true),
        ),
      ));
      final container = tester.widget<Container>(
        find.byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == Colors.green),
      );
      expect(container, isNotNull);
    });

    testWidgets('shows red dot when offline', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StatusIndicator(isOnline: false),
        ),
      ));
      final container = tester.widget<Container>(
        find.byWidgetPredicate((w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == Colors.red),
      );
      expect(container, isNotNull);
    });
  });
}
