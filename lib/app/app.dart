import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/auth/presentation/pages/phone_continue_page.dart';
import '../features/auth/presentation/pages/phone_verify_page.dart';
import '../features/auth/presentation/pages/success_page.dart';
import '../features/student_dashboard/presentation/pages/home_page.dart';
import '../features/student_courses/presentation/pages/course_page.dart';
import '../features/student_courses/presentation/pages/search_results_page.dart';
import '../features/student_courses/presentation/pages/course_detail_page.dart';
import '../features/student_courses/presentation/pages/course_player_page.dart';
import '../features/student_dashboard/presentation/pages/payment_method_page.dart';
import '../features/student_dashboard/presentation/pages/purchase_success_page.dart';
import '../features/student_attendance/presentation/pages/clocking_in_modal.dart';
import '../features/student_courses/presentation/pages/my_courses_page.dart';
import '../features/student_profile/presentation/pages/account_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/notifications/presentation/pages/no_notifications_page.dart';
import '../features/notifications/presentation/pages/no_network_page.dart';
import '../features/student_courses/presentation/pages/no_videos_page.dart';
import '../features/student_dashboard/presentation/pages/no_products_page.dart';
import '../features/student_dashboard/presentation/pages/learn_today_page.dart';
import '../features/student_dashboard/presentation/pages/meetup_page.dart';
import '../features/student_courses/presentation/pages/learning_plan_detail_page.dart';
import '../features/student_courses/presentation/pages/learning_plan_video_page.dart';
import '../features/student_courses/presentation/pages/learning_plan_message_page.dart';
import '../features/student_courses/presentation/pages/learning_plan_schedule_page.dart';
import '../features/student_courses/presentation/pages/learning_plan_live_page.dart';
import '../core/constants/learning_plan_courses.dart';
import '../features/student_profile/presentation/pages/favourite_page.dart';
import '../features/student_profile/presentation/pages/settings_privacy_page.dart';
import '../features/student_profile/presentation/pages/help_page.dart';
import '../features/notifications/presentation/pages/message_thread_page.dart';
import '../features/notifications/domain/entities/message_notification.dart';
import '../features/auth/presentation/pages/role_select_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/teacher_dashboard/presentation/pages/teacher_home_page.dart';
import '../features/teacher_courses/presentation/pages/teacher_courses_page.dart';
import '../features/teacher_dashboard/presentation/pages/teacher_search_page.dart';
import '../features/chat/presentation/pages/teacher_messages_page.dart';
import '../features/teacher_profile/presentation/pages/teacher_account_page.dart';
import '../features/teacher_dashboard/presentation/pages/teacher_professionals_page.dart';
import '../features/teacher_dashboard/presentation/pages/teacher_reports_page.dart';
import '../features/teacher_courses/presentation/pages/teacher_create_course_page.dart';
import '../features/teacher_attendance/presentation/pages/teacher_schedule_session_page.dart';
import '../features/teacher_assignments/presentation/pages/teacher_requests_page.dart';
import '../features/teacher_assignments/presentation/pages/teacher_manage_students_page.dart';
import '../features/teacher_assignments/presentation/pages/teacher_share_invite_page.dart';
import '../features/teacher_profile/presentation/pages/teacher_payout_settings_page.dart';
import '../features/teacher_courses/presentation/pages/teacher_course_overview_page.dart';
import '../features/teacher_attendance/presentation/pages/teacher_student_logins_page.dart';
import '../features/teacher_courses/presentation/pages/teacher_course_detail_page.dart';
import '../features/teacher_courses/presentation/pages/teacher_manage_curriculum_page.dart';
import '../features/teacher_profile/presentation/pages/teacher_student_profile_page.dart';
import '../core/sensors/widgets/sensor_warning_widget.dart';
import '../core/sensors/shake_detector_wrapper.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  String? _asString(Object? value) {
    return value is String ? value : null;
  }

  Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Tutor App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const SensorWarningWidget(),
            const ShakeDetectorWrapper(),
          ],
        );
      },
      initialRoute: AppRoutes.onboarding,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const OnboardingPage());
          case AppRoutes.onboarding:
            return MaterialPageRoute(builder: (_) => const OnboardingPage());
          case AppRoutes.login:
            return MaterialPageRoute(
              builder: (_) => LoginPage(role: _asString(settings.arguments)),
            );
          case AppRoutes.signup:
            return MaterialPageRoute(
              builder: (_) => SignUpPage(role: _asString(settings.arguments)),
            );
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
                query: _asString(settings.arguments),
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
            return MaterialPageRoute(
                builder: (_) => const PurchaseSuccessPage());
          case AppRoutes.clockingIn:
            return MaterialPageRoute(builder: (_) => const ClockingInModal());
          case AppRoutes.myCourses:
            return MaterialPageRoute(builder: (_) => const MyCoursesPage());
          case AppRoutes.account:
            return MaterialPageRoute(builder: (_) => const AccountPage());
          case AppRoutes.notifications:
            return MaterialPageRoute(builder: (_) => const NotificationsPage());
          case AppRoutes.noNotifications:
            return MaterialPageRoute(
                builder: (_) => const NoNotificationsPage());
          case AppRoutes.noNetwork:
            return MaterialPageRoute(builder: (_) => const NoNetworkPage());
          case AppRoutes.noVideos:
            return MaterialPageRoute(builder: (_) => const NoVideosPage());
          case AppRoutes.noProducts:
            return MaterialPageRoute(builder: (_) => const NoProductsPage());
          case AppRoutes.learnToday:
            return MaterialPageRoute(builder: (_) => const LearnTodayPage());
          case AppRoutes.meetup:
            return MaterialPageRoute(builder: (_) => const MeetupPage());
          case AppRoutes.learningPlanDetail:
            final args = settings.arguments;
            if (args is! LearningPlanCourse) {
              return MaterialPageRoute(builder: (_) => const HomePage());
            }
            return MaterialPageRoute(
              builder: (_) => LearningPlanDetailPage(course: args),
            );
          case AppRoutes.learningPlanVideo:
            final args = settings.arguments;
            if (args is! Map<String, dynamic>) {
              return MaterialPageRoute(builder: (_) => const HomePage());
            }
            final course = args['course'];
            final module = args['module'];
            if (course is! LearningPlanCourse || module is! String) {
              return MaterialPageRoute(builder: (_) => const HomePage());
            }
            return MaterialPageRoute(
              builder: (_) => LearningPlanVideoPage(
                course: course,
                module: module,
              ),
            );
          case AppRoutes.learningPlanMessage:
            final args = settings.arguments;
            if (args is! LearningPlanCourse) {
              return MaterialPageRoute(builder: (_) => const HomePage());
            }
            return MaterialPageRoute(
              builder: (_) => LearningPlanMessagePage(course: args),
            );
          case AppRoutes.learningPlanSchedule:
            final args = settings.arguments;
            if (args is! LearningPlanCourse) {
              return MaterialPageRoute(builder: (_) => const HomePage());
            }
            return MaterialPageRoute(
              builder: (_) => LearningPlanSchedulePage(course: args),
            );
          case AppRoutes.learningPlanLive:
            final args = settings.arguments;
            if (args is! LearningPlanCourse) {
              return MaterialPageRoute(builder: (_) => const HomePage());
            }
            return MaterialPageRoute(
              builder: (_) => LearningPlanLivePage(course: args),
            );
          case AppRoutes.favourites:
            return MaterialPageRoute(builder: (_) => const FavouritePage());
          case AppRoutes.settingsPrivacy:
            return MaterialPageRoute(
                builder: (_) => const SettingsPrivacyPage());
          case AppRoutes.help:
            return MaterialPageRoute(builder: (_) => const HelpPage());
          case AppRoutes.messageThread:
            final args = settings.arguments;
            if (args is! MessageNotification) {
              return MaterialPageRoute(builder: (_) => const HomePage());
            }
            return MaterialPageRoute(
              builder: (_) => MessageThreadPage(message: args),
            );
          case AppRoutes.roleSelect:
            return MaterialPageRoute(
              builder: (_) => RoleSelectPage(
                action: _asString(settings.arguments),
              ),
            );
          case AppRoutes.forgotPassword:
            return MaterialPageRoute(
              builder: (_) => ForgotPasswordPage(
                role: _asString(settings.arguments),
              ),
            );
          case AppRoutes.teacherHome:
            return MaterialPageRoute(builder: (_) => const TeacherHomePage());
          case AppRoutes.teacherCourses:
            return MaterialPageRoute(
                builder: (_) => const TeacherCoursesPage());
          case AppRoutes.teacherSearch:
            return MaterialPageRoute(builder: (_) => const TeacherSearchPage());
          case AppRoutes.teacherMessages:
            return MaterialPageRoute(
                builder: (_) => const TeacherMessagesPage());
          case AppRoutes.teacherAccount:
            return MaterialPageRoute(
                builder: (_) => const TeacherAccountPage());
          case AppRoutes.teacherProfessionals:
            return MaterialPageRoute(
                builder: (_) => const TeacherProfessionalsPage());
          case AppRoutes.teacherReports:
            return MaterialPageRoute(
                builder: (_) => const TeacherReportsPage());
          case AppRoutes.teacherCreateCourse:
            return MaterialPageRoute(
                builder: (_) => const TeacherCreateCoursePage());
          case AppRoutes.teacherScheduleSession:
            return MaterialPageRoute(
                builder: (_) => const TeacherScheduleSessionPage());
          case AppRoutes.teacherRequests:
            return MaterialPageRoute(
                builder: (_) => const TeacherRequestsPage());
          case AppRoutes.teacherManageStudents:
            return MaterialPageRoute(
                builder: (_) => const TeacherManageStudentsPage());
          case AppRoutes.teacherShareInvite:
            return MaterialPageRoute(
                builder: (_) => const TeacherShareInvitePage());
          case AppRoutes.teacherPayoutSettings:
            return MaterialPageRoute(
                builder: (_) => const TeacherPayoutSettingsPage());
          case AppRoutes.teacherCourseOverview:
            return MaterialPageRoute(
                builder: (_) => const TeacherCourseOverviewPage());
          case AppRoutes.teacherStudentLogins:
            return MaterialPageRoute(
                builder: (_) => const TeacherStudentLoginsPage());
          case AppRoutes.teacherCourseDetail:
            return MaterialPageRoute(
              builder: (_) => TeacherCourseDetailPage(
                course: _asMap(settings.arguments),
              ),
            );
          case AppRoutes.teacherManageCurriculum:
            return MaterialPageRoute(
              builder: (_) => TeacherManageCurriculumPage(
                course: _asMap(settings.arguments),
              ),
            );
          case AppRoutes.teacherStudentProfile:
            return MaterialPageRoute(
              builder: (_) => TeacherStudentProfilePage(
                student: _asMap(settings.arguments),
              ),
            );
          default:
            return MaterialPageRoute(builder: (_) => const LoginPage());
        }
      },
    );
  }
}
