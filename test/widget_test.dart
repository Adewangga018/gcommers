import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gcommers/main.dart';

void main() {
  testWidgets('renders splash then login flow', (WidgetTester tester) async {
    await tester.pumpWidget(const GCommersApp());

    expect(find.text('GCommers'), findsWidgets);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('MASUK'), findsOneWidget);
  });
}
