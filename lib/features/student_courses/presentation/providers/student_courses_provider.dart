import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/student_courses_local_datasource.dart';
import '../../data/datasources/remote/student_courses_remote_datasource.dart';
import '../../data/repositories/student_courses_repository_impl.dart';
import '../../domain/repositories/student_courses_repository.dart';
import '../view_model/course_catalog_state.dart';
import '../view_model/course_catalog_view_model.dart';

final studentCoursesLocalDataSourceProvider =
    Provider<StudentCoursesLocalDataSource>((ref) {
  return const StudentCoursesLocalDataSource();
});

final studentCoursesRemoteDataSourceProvider =
    Provider<StudentCoursesRemoteDataSource>((ref) {
  return StudentCoursesRemoteDataSource();
});

final studentCoursesRepositoryProvider = Provider<StudentCoursesRepository>((ref) {
  final local = ref.watch(studentCoursesLocalDataSourceProvider);
  final remote = ref.watch(studentCoursesRemoteDataSourceProvider);
  return StudentCoursesRepositoryImpl(remote: remote, local: local);
});

final courseCatalogViewModelProvider =
    StateNotifierProvider.autoDispose<CourseCatalogViewModel, CourseCatalogState>(
        (ref) {
  final repo = ref.watch(studentCoursesRepositoryProvider);
  return CourseCatalogViewModel(repo);
});

