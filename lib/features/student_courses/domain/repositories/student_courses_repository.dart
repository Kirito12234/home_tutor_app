import '../entities/course.dart';

abstract class StudentCoursesRepository {
  Future<List<Course>> fetchCourses({
    required bool isStudent,
    String searchQuery = '',
  });

  Future<Set<String>> fetchFavoriteCourseIds();

  Future<void> toggleFavorite({
    required String courseId,
    required bool shouldBeFavorite,
  });
}

