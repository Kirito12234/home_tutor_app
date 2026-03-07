import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/hive/hive_service.dart';
import '../../domain/entities/course.dart';
import '../../domain/repositories/student_courses_repository.dart';
import 'course_catalog_state.dart';

class CourseCatalogViewModel extends StateNotifier<CourseCatalogState> {
  CourseCatalogViewModel(this._repository) : super(const CourseCatalogState());

  final StudentCoursesRepository _repository;

  bool get _isStudent =>
      HiveService.currentUserRole?.toLowerCase() == 'student';

  Future<void> loadInitialData({String searchQuery = ''}) async {
    await Future.wait<void>([
      refreshCourses(searchQuery: searchQuery),
      refreshFavorites(),
    ]);
  }

  Future<void> refreshCourses({String searchQuery = ''}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final courses = await _repository.fetchCourses(
        isStudent: _isStudent,
        searchQuery: searchQuery,
      );
      state = state.copyWith(isLoading: false, courses: courses);
    } catch (err) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: err.toString(),
        courses: const <Course>[],
      );
    }
  }

  Future<void> refreshFavorites() async {
    try {
      final ids = await _repository.fetchFavoriteCourseIds();
      state = state.copyWith(favoriteCourseIds: ids);
    } catch (_) {
      // Non-blocking by design.
    }
  }

  Future<void> toggleFavorite(Course course) async {
    final next = {...state.favoriteCourseIds};
    final isFavorite = next.contains(course.id);
    if (isFavorite) {
      next.remove(course.id);
    } else {
      next.add(course.id);
    }
    state = state.copyWith(favoriteCourseIds: next);

    try {
      await _repository.toggleFavorite(
        courseId: course.id,
        shouldBeFavorite: !isFavorite,
      );
    } catch (_) {
      final revert = {...state.favoriteCourseIds};
      if (isFavorite) {
        revert.add(course.id);
      } else {
        revert.remove(course.id);
      }
      state = state.copyWith(favoriteCourseIds: revert);
    }
  }
}

