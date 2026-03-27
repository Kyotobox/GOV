// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vanguard_agent/main.dart';

void main() {
  testWidgets('Vanguard Agent UI Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VanguardAgent());

    // 1. Verify that the title contains "VANGUARD"
    expect(find.textContaining('VANGUARD'), findsOneWidget);

    // 2. Verify initial status (Waiting for project)
    expect(find.text('Inicie un proyecto...'), findsOneWidget);
    
    // 3. Check for the Emergency Panic button (nuke)
    expect(find.text('EMERGENCY PANIC (NUKE)'), findsOneWidget);

    // 4. Verify that the Drawer is present
    expect(find.byType(Drawer), findsNothing); // It's a Scaffold drawer, not open initially
  });
}
