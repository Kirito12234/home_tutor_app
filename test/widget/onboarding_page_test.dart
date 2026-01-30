import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_tutor_app/core/widgets/page_dots.dart';
import 'package:home_tutor_app/features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  testWidgets('Onboarding page renders without overflow', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Page dots indicator exists', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
    await tester.pumpAndSettle();

    expect(find.byType(PageDots), findsOneWidget);
  });

  testWidgets('Primary action button exists on role selection page', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(PageView),
      const Offset(-1080, 0),
      1200,
    );
    await tester.pumpAndSettle();

    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
  });
}
