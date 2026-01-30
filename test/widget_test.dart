// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:home_tutor_app/app/app.dart';
import 'utils/hive_test_utils.dart';

void main() {
  setUpAll(() async {
    await HiveTestUtils.ensureInitialized();
  });

  tearDownAll(() async {
    await HiveTestUtils.dispose();
  });

  setUp(() async {
    await HiveTestUtils.clearBox();
  });

  testWidgets('App loads successfully', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
