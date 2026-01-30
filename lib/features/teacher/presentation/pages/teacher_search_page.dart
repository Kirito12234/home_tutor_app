import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../widgets/teacher_bottom_nav.dart';

class TeacherSearchPage extends StatefulWidget {
  const TeacherSearchPage({Key? key}) : super(key: key);

  @override
  State<TeacherSearchPage> createState() => _TeacherSearchPageState();
}

class _TeacherSearchPageState extends State<TeacherSearchPage> {
  int _currentNavIndex = 2;
  final TextEditingController _searchController = TextEditingController();
  final ApiClient _apiClient = ApiClient();
  final List<_CourseResult> _courses = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _query = '';
  Timer? _debounce;

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherHome);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherCourses);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherMessages);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherAccount);
        break;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final value = _searchController.text.trim().toLowerCase();
    setState(() {
      _query = value;
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _loadCourses);
  }

  Future<void> _loadCourses() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'Please log in to search courses.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final instructor = HiveService.currentUserName;
      final params = <String, String>{};
      if (instructor != null && instructor.trim().isNotEmpty) {
        params['instructor'] = instructor;
      }
      if (_query.isNotEmpty) {
        params['search'] = _query;
      }
      final query = params.entries
          .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value)}')
          .join('&');
      final path = query.isEmpty ? '/api/v1/courses' : '/api/v1/courses?$query';
      final response = await _apiClient.getJson(
        path,
        token: token,
      );
      final data = response['data'];
      if (data is List) {
        final mapped = data
            .whereType<Map<String, dynamic>>()
            .map(_CourseResult.fromJson)
            .toList();
        setState(() {
          _courses
            ..clear()
            ..addAll(mapped);
        });
      } else {
        setState(() {
          _errorMessage = 'Unexpected response format.';
        });
      }
    } on HttpException catch (err) {
      setState(() {
        _errorMessage = err.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to load courses.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _courses;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.teacherHome,
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.teacherBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.teacherPrimaryDark),
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.teacherHome,
              (route) => false,
            ),
          ),
          title: const Text(
            'Search',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.teacherPrimaryDark,
              fontFamily: 'Inter',
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search courses',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.teacherSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.redAccent,
                              fontFamily: 'Inter',
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          children: results
                              .map(
                                (item) => ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.teacherChip,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.menu_book,
                                      color: AppColors.teacherPrimaryDark,
                                    ),
                                  ),
                                  title: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  subtitle: Text(
                                    item.subtitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.teacherMuted,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  trailing: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pushNamed(
                                        AppRoutes.teacherCourseDetail,
                                        arguments: item.toDetailMap(),
                                      );
                                    },
                                    child: const Text(
                                      'View',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.teacherPrimary,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
            ),
            TeacherBottomNav(
              currentIndex: _currentNavIndex,
              onTap: _onNavTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseResult {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String instructor;
  final int durationHours;
  final int lessonCount;

  const _CourseResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.instructor,
    required this.durationHours,
    required this.lessonCount,
  });

  static _CourseResult fromJson(Map<String, dynamic> json) {
    return _CourseResult(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Course',
      subtitle: json['description']?.toString() ?? 'Course details',
      category: json['category']?.toString() ?? 'General',
      instructor: json['instructorName']?.toString() ?? 'Instructor',
      durationHours: (json['durationHours'] as num?)?.toInt() ?? 0,
      lessonCount: (json['lessonCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toDetailMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'level': category,
      'mentor': instructor,
      'weeks': '$durationHours hours',
      'progress': '0 / ${lessonCount == 0 ? 1 : lessonCount}',
      'students': '0 students',
      'status': 'Active',
    };
  }
}


