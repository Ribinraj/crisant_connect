import 'package:crisant_connect/features/dashboard/pages/screen_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crisant_connect/main.dart';

void main() {
  testWidgets('shows login screen after splash', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Welcome to Crisant Connect'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.byType(EditableText), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('dashboard renders without vertical overflow on narrow screens', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: ScreenDashboard()));

    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -520));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
