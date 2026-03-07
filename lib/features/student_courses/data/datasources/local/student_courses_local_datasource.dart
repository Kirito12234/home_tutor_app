import '../../../../../core/services/hive/hive_service.dart';

class StudentCoursesLocalDataSource {
  const StudentCoursesLocalDataSource();

  String? get authToken => HiveService.authToken;
  String? get currentUserRole => HiveService.currentUserRole;
}

