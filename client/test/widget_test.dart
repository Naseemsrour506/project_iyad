// Basic smoke test for the SafeKid app.
//
// Verifies that the app launches into the parent dashboard and renders
// the alerts section with at least one alert card.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client/main.dart';

void main() {
  testWidgets('Parent dashboard launches and shows alerts', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const SafeKidApp());

    // The dashboard title and alerts header are visible.
    expect(find.text('לוח בקרה להורה'), findsOneWidget);
    expect(find.text('התראות אחרונות'), findsOneWidget);

    // At least one alert card is rendered.
    expect(find.byType(Card), findsWidgets);
  });
}
