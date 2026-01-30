import 'package:flutter_test/flutter_test.dart';
import 'package:home_tutor_app/app/routes/app_routes.dart';

void main() {
  group('AppRoutes', () {
    test('login route exists', () {
      expect(AppRoutes.login, equals('/login'));
    });

    test('signup route exists', () {
      expect(AppRoutes.signup, equals('/signup'));
    });

    test('home route exists', () {
      expect(AppRoutes.home, equals('/home'));
    });
  });
}
