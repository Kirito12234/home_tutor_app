import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../student_courses/domain/entities/course.dart';
import '../../domain/entities/lesson.dart';

class LearningPlanCard extends StatefulWidget {
  const LearningPlanCard({Key? key}) : super(key: key);

  @override
  State<LearningPlanCard> createState() => _LearningPlanCardState();
}

class _LearningPlanCardState extends State<LearningPlanCard> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  String? _errorMessage;
  final List<_LearningPlanItem> _courses = <_LearningPlanItem>[];

  bool get _isStudent => HiveService.currentUserRole?.toLowerCase() == 'student';

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      List<_LearningPlanItem> mapped = <_LearningPlanItem>[];

      if (_isStudent) {
        mapped = await _loadFromEnrollments();
      }

      if (mapped.isEmpty) {
        final params = <String>[];
        if (_isStudent) {
          params.add('status=approved');
        }
        final query = params.isEmpty ? '' : '?${params.join('&')}';
        final response = await _apiClient.getJson(
          '/api/v1/courses$query',
          token: HiveService.authToken,
        );
        final data = response['data'];
        if (data is! List) {
          throw Exception('Unexpected response format');
        }
        mapped = data
            .whereType<Map<String, dynamic>>()
            .where(_isCourseApprovedForStudent)
            .map((courseMap) => _LearningPlanItem(
                  course: _mapCourse(courseMap),
                  createdAt: _parseDateTime(
                    courseMap['createdAt']?.toString(),
                  ),
                ))
            .toList();
      }
      mapped.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (!mounted) {
        return;
      }
      setState(() {
        _courses
          ..clear()
          ..addAll(mapped.take(8));
      });
    } on HttpException catch (err) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = err.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Unable to load learning plans.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<_LearningPlanItem>> _loadFromEnrollments() async {
    final response = await _apiClient.getJson(
      '/api/v1/enrollments',
      token: HiveService.authToken,
    );
    final data = response['data'];
    if (data is! List) {
      return <_LearningPlanItem>[];
    }

    final items = <_LearningPlanItem>[];
    for (final raw in data.whereType<Map<String, dynamic>>()) {
      final status = raw['status']?.toString().toLowerCase() ?? '';
      final approved = status == 'approved' ||
          status == 'paid' ||
          status == 'completed' ||
          raw['isApproved'] == true;
      if (!approved) {
        continue;
      }

      final courseRaw = raw['course'];
      if (courseRaw is! Map<String, dynamic>) {
        continue;
      }

      final id = courseRaw['_id']?.toString() ?? courseRaw['id']?.toString() ?? '';
      var lessonCount = (courseRaw['lessonCount'] as num?)?.toInt() ?? 0;
      if (id.isNotEmpty) {
        lessonCount = await _resolveLatestLessonCount(id, lessonCount);
      }

      final course = _mapCourse({
        ...courseRaw,
        'lessonCount': lessonCount,
      });

      final progressPercent = (raw['progressPercent'] as num?)?.toDouble() ?? 0.0;
      final enrollmentDate = _parseDateTime(
        raw['updatedAt']?.toString() ??
            raw['createdAt']?.toString() ??
            courseRaw['createdAt']?.toString(),
      );
      if (progressPercent >= 0) {
        items.add(
          _LearningPlanItem(
            course: course,
            createdAt: enrollmentDate,
          ),
        );
      }
    }
    return items;
  }

  DateTime _parseDateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.tryParse(value.trim()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _assetUrl(String? path) {
    if (path == null || path.trim().isEmpty) {
      return '';
    }
    final raw = path.trim();
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    final base = socketBaseUrl();
    if (raw.startsWith('/')) {
      return '$base$raw';
    }
    return '$base/$raw';
  }

  Future<int> _resolveLatestLessonCount(String courseId, int fallback) async {
    try {
      final lessonsResponse = await _apiClient.getJson(
        '/api/v1/courses/$courseId/lessons',
        token: HiveService.authToken,
      );
      final data = lessonsResponse['data'];
      if (data is List) {
        return data.length;
      }
    } catch (_) {}

    try {
      final courseResponse = await _apiClient.getJson(
        '/api/v1/courses/$courseId',
        token: HiveService.authToken,
      );
      final data = courseResponse['data'];
      if (data is Map<String, dynamic>) {
        final count = (data['lessonCount'] as num?)?.toInt();
        if (count != null && count >= 0) {
          return count;
        }
      }
    } catch (_) {}

    return fallback;
  }

  bool _isCourseApprovedForStudent(Map<String, dynamic> course) {
    if (!_isStudent) {
      return true;
    }
    final explicitApproved =
        course['isApproved'] == true || course['approved'] == true;
    final approvalStatus =
        course['approvalStatus']?.toString().toLowerCase() ?? '';
    final status = course['status']?.toString().toLowerCase() ?? '';

    if (approvalStatus == 'rejected' ||
        approvalStatus == 'pending' ||
        approvalStatus == 'draft' ||
        status == 'rejected' ||
        status == 'pending' ||
        status == 'draft') {
      return false;
    }

    return explicitApproved ||
        approvalStatus == 'approved' ||
        status == 'approved';
  }

  Course _mapCourse(Map<String, dynamic> course) {
    final tutor = course['tutor'];
    final tutorName =
        tutor is Map<String, dynamic> ? tutor['name']?.toString() : null;
    final tutorId = tutor is Map<String, dynamic> ? tutor['_id']?.toString() : null;
    return Course(
      id: course['_id']?.toString() ?? course['id']?.toString() ?? 'course',
      title: course['title']?.toString() ?? 'Course',
      instructor: course['instructorName']?.toString() ?? tutorName ?? 'Instructor',
      tutorId: tutorId,
      price: (course['price'] as num?)?.toDouble() ?? 0,
      durationHours: (course['durationHours'] as num?)?.toInt() ?? 0,
      lessonCount: (course['lessonCount'] as num?)?.toInt() ?? 0,
      category: course['category']?.toString() ?? 'General',
      imageUrl: course['imageUrl']?.toString(),
      description: course['description']?.toString() ?? '',
      isBestseller: course['isBestseller'] == true,
      isPopular: course['isPopular'] == true,
      isNew: course['isNew'] == true,
      lessons: const <Lesson>[],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Learning Plan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'OpenSans',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _courses.isEmpty ? 'No recent courses.' : 'Recently created courses',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontFamily: 'OpenSans',
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.redAccent,
                  fontFamily: 'OpenSans',
                ),
              ),
            ),
          if (!_isLoading && _errorMessage == null && _courses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No approved courses yet.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontFamily: 'OpenSans',
                ),
              ),
            ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _courses.length,
            separatorBuilder: (_, __) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final item = _courses[index];
              final course = item.course;
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.courseDetail,
                    arguments: course,
                  );
                },
                child: _buildPlanItem(
                  course: course,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlanItem({
    required Course course,
  }) {
    final imageUrl = _assetUrl(course.imageUrl);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.menu_book,
                      color: AppColors.textSecondary,
                    ),
                  )
                : const Icon(
                    Icons.menu_book,
                    color: AppColors.textSecondary,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'OpenSans',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${course.category} · Rs ${course.price.toStringAsFixed(0)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontFamily: 'OpenSans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  course.instructor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningPlanItem {
  const _LearningPlanItem({
    required this.course,
    required this.createdAt,
  });

  final Course course;
  final DateTime createdAt;
}




