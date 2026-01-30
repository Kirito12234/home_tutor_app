import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_tutor_app/core/widgets/app_text_field.dart';
import 'package:home_tutor_app/core/widgets/page_dots.dart';
import 'package:home_tutor_app/core/widgets/primary_button.dart';

void main() {
  testWidgets('PrimaryButton shows loading indicator when isLoading is true',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            text: 'Continue',
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Continue'), findsNothing);
  });

  testWidgets('PrimaryButton shows text when not loading', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(
            text: 'Continue',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('Continue'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('PageDots renders the correct number of dots', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: PageDots(
          currentIndex: 1,
          totalPages: 3,
        ),
      ),
    );

    final dots = find.byType(Container);
    expect(dots, findsNWidgets(3));
  });

  testWidgets('PageDots marks the active dot with a wider width', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: PageDots(
          currentIndex: 0,
          totalPages: 4,
        ),
      ),
    );

    final dots = find.byType(Container);
    final widths = <double>[];
    for (var i = 0; i < 4; i++) {
      final size = tester.getSize(dots.at(i));
      widths.add(size.width);
    }
    final maxWidth = widths.reduce((a, b) => a > b ? a : b);
    final minWidth = widths.reduce((a, b) => a < b ? a : b);
    final activeCount = widths.where((width) => width == maxWidth).length;
    expect(activeCount, 1);
    expect(maxWidth > minWidth, isTrue);
  });

  testWidgets('AppTextField respects obscureText setting', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Form(
            child: AppTextField(
              hintText: 'Password',
              obscureText: true,
            ),
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.obscureText, isTrue);
  });
}
