import 'package:flutter/material.dart';

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String phoneContinue = '/phone-continue';
  static const String phoneVerify = '/phone-verify';
  static const String success = '/success';
  static const String home = '/home';
  static const String courses = '/courses';
  static const String searchResults = '/search-results';
  static const String courseDetail = '/course-detail';
  static const String coursePlayer = '/course-player';
  static const String paymentMethod = '/payment-method';
  static const String purchaseSuccess = '/purchase-success';
  static const String clockingIn = '/clocking-in';
  static const String myCourses = '/my-courses';
  static const String account = '/account';
  static const String notifications = '/notifications';
  static const String noNotifications = '/no-notifications';
  static const String noNetwork = '/no-network';
  static const String noVideos = '/no-videos';
  static const String noProducts = '/no-products';
  static const String learnToday = '/learn-today';
  static const String meetup = '/meetup';
  static const String learningPlanDetail = '/learning-plan-detail';
  static const String learningPlanVideo = '/learning-plan-video';
  static const String learningPlanMessage = '/learning-plan-message';
  static const String learningPlanSchedule = '/learning-plan-schedule';
  static const String learningPlanLive = '/learning-plan-live';
  static const String favourites = '/favourites';
  static const String settingsPrivacy = '/settings-privacy';
  static const String help = '/help';
  static const String messageThread = '/message-thread';
  static const String roleSelect = '/role-select';
  static const String teacherHome = '/teacher-home';
  static const String teacherCourses = '/teacher-courses';
  static const String teacherSearch = '/teacher-search';
  static const String teacherMessages = '/teacher-messages';
  static const String teacherAccount = '/teacher-account';
  static const String teacherProfessionals = '/teacher-professionals';
  static const String teacherReports = '/teacher-reports';
  static const String teacherCreateCourse = '/teacher-create-course';
  static const String teacherScheduleSession = '/teacher-schedule-session';
  static const String teacherRequests = '/teacher-requests';
  static const String teacherManageStudents = '/teacher-manage-students';
  static const String teacherShareInvite = '/teacher-share-invite';
  static const String teacherPayoutSettings = '/teacher-payout-settings';
  static const String teacherCourseOverview = '/teacher-course-overview';
  static const String teacherStudentLogins = '/teacher-student-logins';
  static const String teacherCourseDetail = '/teacher-course-detail';
  static const String teacherManageCurriculum = '/teacher-manage-curriculum';
  static const String teacherStudentProfile = '/teacher-student-profile';
  static const String forgotPassword = '/forgot-password';

  static Future<T?> pushNamed<T>(
    BuildContext context,
    String route, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamed<T>(route, arguments: arguments);
  }

  static Future<T?> pushReplacementNamed<T, TO>(
    BuildContext context,
    String route, {
    TO? result,
    Object? arguments,
  }) {
    return Navigator.of(
      context,
    ).pushReplacementNamed<T, TO>(route, result: result, arguments: arguments);
  }
}
