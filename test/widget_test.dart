import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fluent_check_mvp/main.dart';

void main() {
  testWidgets('Landing page renders recorder UI', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('00:00'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
    expect(find.text('Filler words will appear here'), findsOneWidget);
  });
}
