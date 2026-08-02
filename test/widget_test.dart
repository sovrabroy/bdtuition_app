// Basic smoke test — just verifies the app boots without crashing.
//
// The default Flutter counter test was replaced because BDTuition has no
// counter; it launches into the splash screen instead.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bdtuition_app/main.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    // Build the app and let the first frame settle.
    await tester.pumpWidget(const BDTuitionApp());
    await tester.pump();

    // The root MaterialApp should be present.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
