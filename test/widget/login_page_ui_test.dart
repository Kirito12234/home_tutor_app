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

  testWidgets('LoginPage shows email and password fields', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(TextFormField, 'Email or phone'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
  });

  testWidgets('LoginPage shows login button', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: LoginPage()));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ElevatedButton, 'Log In'), findsOneWidget);
  });
}
