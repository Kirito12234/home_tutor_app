import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import '../core/services/hive/hive_service.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/auth/presentation/pages/phone_continue_page.dart';
import '../features/auth/presentation/pages/phone_verify_page.dart';
import '../features/auth/presentation/pages/success_page.dart';
import '../features/dashboard/presentation/pages/home_page.dart';
import '../features/courses/presentation/pages/course_page.dart';
import '../features/courses/presentation/pages/search_results_page.dart';
import '../features/courses/presentation/pages/course_detail_page.dart';
import '../features/courses/presentation/pages/course_player_page.dart';
import '../features/payments/presentation/pages/payment_method_page.dart';
import '../features/payments/presentation/pages/purchase_success_page.dart';
import '../features/progress/presentation/pages/clocking_in_modal.dart';
import '../features/my_courses/presentation/pages/my_courses_page.dart';
import '../features/account/presentation/pages/account_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/notifications/presentation/pages/no_notifications_page.dart';
import '../features/notifications/presentation/pages/no_network_page.dart';
import '../features/empty_states/presentation/pages/no_videos_page.dart';
import '../features/empty_states/presentation/pages/no_products_page.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Tutor App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (_) {
                if (HiveService.isOnboardingDone) {
                  return const LoginPage();
                } else {
                  return const OnboardingPage();
                }
              },
            );
          case AppRoutes.onboarding:
            return MaterialPageRoute(builder: (_) => const OnboardingPage());
          case AppRoutes.login:
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case AppRoutes.signup:
            return MaterialPageRoute(builder: (_) => const SignUpPage());
          case AppRoutes.phoneContinue:
            return MaterialPageRoute(builder: (_) => const PhoneContinuePage());
          case AppRoutes.phoneVerify:
            return MaterialPageRoute(
              builder: (_) => const PhoneVerifyPage(),
              settings: settings,
            );
          case AppRoutes.success:
            return MaterialPageRoute(builder: (_) => const SuccessPage());
          case AppRoutes.home:
            return MaterialPageRoute(builder: (_) => const HomePage());
          case AppRoutes.courses:
            return MaterialPageRoute(builder: (_) => const CoursePage());
          case AppRoutes.searchResults:
            return MaterialPageRoute(
              builder: (_) => SearchResultsPage(
                query: settings.arguments as String?,
              ),
            );
          case AppRoutes.courseDetail:
            return MaterialPageRoute(
              builder: (_) => const CourseDetailPage(),
              settings: settings,
            );
          case AppRoutes.coursePlayer:
            return MaterialPageRoute(
              builder: (_) => const CoursePlayerPage(),
              settings: settings,
            );
          case AppRoutes.paymentMethod:
            return MaterialPageRoute(builder: (_) => const PaymentMethodPage());
          case AppRoutes.purchaseSuccess:
            return MaterialPageRoute(builder: (_) => const PurchaseSuccessPage());
          case AppRoutes.clockingIn:
            return MaterialPageRoute(builder: (_) => const ClockingInModal());
          case AppRoutes.myCourses:
            return MaterialPageRoute(builder: (_) => const MyCoursesPage());
          case AppRoutes.account:
            return MaterialPageRoute(builder: (_) => const AccountPage());
          case AppRoutes.notifications:
            return MaterialPageRoute(builder: (_) => const NotificationsPage());
          case AppRoutes.noNotifications:
            return MaterialPageRoute(builder: (_) => const NoNotificationsPage());
          case AppRoutes.noNetwork:
            return MaterialPageRoute(builder: (_) => const NoNetworkPage());
          case AppRoutes.noVideos:
            return MaterialPageRoute(builder: (_) => const NoVideosPage());
          case AppRoutes.noProducts:
            return MaterialPageRoute(builder: (_) => const NoProductsPage());
          default:
            return MaterialPageRoute(builder: (_) => const LoginPage());
        }
      },
    );
  }
}

