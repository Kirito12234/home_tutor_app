import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_tutor_app/features/auth/presentation/pages/login_page.dart';
import '../utils/hive_test_utils.dart';

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

  testWidgets('Tapping login with empty fields shows validation error',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email or phone'), findsOneWidget);
  });

  testWidgets('Error message is visible for empty password', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your password'), findsOneWidget);
  });
}
