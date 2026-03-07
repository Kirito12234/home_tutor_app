import '../../domain/entities/course.dart';

class CourseCatalogState {
  const CourseCatalogState({
    this.isLoading = false,
    this.errorMessage,
    this.courses = const <Course>[],
    this.favoriteCourseIds = const <String>{},
  });

  final bool isLoading;
  final String? errorMessage;
  final List<Course> courses;
  final Set<String> favoriteCourseIds;

  CourseCatalogState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<Course>? courses,
    Set<String>? favoriteCourseIds,
  }) {
    return CourseCatalogState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      courses: courses ?? this.courses,
      favoriteCourseIds: favoriteCourseIds ?? this.favoriteCourseIds,
    );
  }
}

