import '../../../../../core/api/api_client.dart';
import '../../../../../core/error/exceptions.dart';
import '../../domain/entities/course.dart';
import '../../domain/repositories/student_courses_repository.dart';
import '../datasources/local/student_courses_local_datasource.dart';
import '../datasources/remote/student_courses_remote_datasource.dart';
import '../models/course_model.dart';

class StudentCoursesRepositoryImpl implements StudentCoursesRepository {
  StudentCoursesRepositoryImpl({
    required StudentCoursesRemoteDataSource remote,
    required StudentCoursesLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final StudentCoursesRemoteDataSource _remote;
  final StudentCoursesLocalDataSource _local;

  @override
  Future<List<Course>> fetchCourses({
    required bool isStudent,
    String searchQuery = '',
  }) async {
    final raw = await _remote.getCourses(
      approvedOnly: isStudent,
      searchQuery: searchQuery,
    );
    return raw.map((json) => CourseModel.fromJson(json).toEntity()).toList();
  }

  @override
  Future<Set<String>> fetchFavoriteCourseIds() async {
    final token = _local.authToken;
    if (token == null || token.isEmpty) {
      return <String>{};
    }

    final paths = <String>[
      '/api/v1/users/me/favorites',
      '/api/users/me/favorites',
      '/api/v1/favorites',
    ];

    for (final path in paths) {
      try {
        final response = await _remote.getFavorites(token: token, path: path);
        final data = response['data'];
        final ids = <String>{};
        if (data is Map<String, dynamic>) {
          final courses = data['courses'];
          if (courses is List) {
            for (final course in courses.whereType<Map<String, dynamic>>()) {
              final id =
                  course['_id']?.toString() ?? course['id']?.toString() ?? '';
              if (id.isNotEmpty) {
                ids.add(id);
              }
            }
          }
        } else if (data is List) {
          for (final row in data.whereType<Map<String, dynamic>>()) {
            final course = row['course'];
            final map =
                course is Map<String, dynamic> ? course : <String, dynamic>{};
            final id = map['_id']?.toString() ??
                map['id']?.toString() ??
                row['_id']?.toString() ??
                row['id']?.toString() ??
                '';
            if (id.isNotEmpty) {
              ids.add(id);
            }
          }
        }
        return ids;
      } on HttpException catch (err) {
        if (_remote.isNotFound(err)) {
          continue;
        }
        return <String>{};
      } catch (_) {
        return <String>{};
      }
    }

    return <String>{};
  }

  @override
  Future<void> toggleFavorite({
    required String courseId,
    required bool shouldBeFavorite,
  }) async {
    final token = _local.authToken;
    if (token == null || token.isEmpty) {
      return;
    }
    final id = courseId.trim();
    if (id.isEmpty) {
      return;
    }

    if (!shouldBeFavorite) {
      final paths = <String>[
        '/api/v1/users/me/favorites/courses/$id',
        '/api/users/me/favorites/courses/$id',
        '/api/v1/favorites/$id',
      ];
      for (final path in paths) {
        try {
          await _remote.removeFavorite(token: token, path: path);
          return;
        } on HttpException catch (err) {
          if (_remote.isNotFound(err)) {
            continue;
          }
          throw AppException(err.message);
        } catch (_) {
          // Try next candidate.
        }
      }
      return;
    }

    final candidates = <Map<String, dynamic>>[
      {
        'path': '/api/v1/users/me/favorites',
        'body': {'courseId': id},
      },
      {
        'path': '/api/users/me/favorites',
        'body': {'courseId': id},
      },
      {
        'path': '/api/v1/favorites',
        'body': {'courseId': id},
      },
      {
        'path': '/api/v1/favorites/courses',
        'body': {'courseId': id},
      },
    ];

    var success = false;
    for (final candidate in candidates) {
      try {
        await _remote.addFavorite(
          token: token,
          path: candidate['path'] as String,
          body: candidate['body'] as Map<String, dynamic>,
        );
        success = true;
        break;
      } on HttpException catch (err) {
        if (_remote.isNotFound(err)) {
          continue;
        }
        throw AppException(err.message);
      } catch (_) {
        // Try next candidate.
      }
    }
    if (!success) {
      throw AppException('Unable to add favorite');
    }
  }
}

