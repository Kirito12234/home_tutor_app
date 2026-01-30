import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../widgets/teacher_bottom_nav.dart';

class TeacherCoursesPage extends StatefulWidget {
  const TeacherCoursesPage({Key? key}) : super(key: key);

  @override
  State<TeacherCoursesPage> createState() => _TeacherCoursesPageState();
}

class _TeacherCoursesPageState extends State<TeacherCoursesPage> {
  int _currentNavIndex = 1;
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, String>> _courses = [];

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherHome);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherSearch);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherMessages);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherAccount);
        break;
    }
  }

  void _showAction(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openCreateCourse() {
    Navigator.of(context)
        .pushNamed(AppRoutes.teacherCreateCourse)
        .then((_) => _loadCourses());
  }

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentName = HiveService.currentUserName;
      final query = (currentName != null && currentName.trim().isNotEmpty)
          ? '?instructor=${Uri.encodeComponent(currentName)}'
          : '';
      final response = await _apiClient.getJson(
        '/api/v1/courses$query',
        token: HiveService.authToken,
      );
      final data = response['data'];
      if (data is List) {
        final mapped = data.map<Map<String, String>>((item) {
          final course = item is Map<String, dynamic> ? item : <String, dynamic>{};
          final duration = course['durationHours'];
          final durationLabel = duration is num ? '${duration.toInt()} hours' : '0 hours';
          final scheduleDate = course['scheduleDate']?.toString();
          final scheduleTime = course['scheduleTime']?.toString();
          final scheduleParts = <String>[];
          if (scheduleDate != null && scheduleDate.isNotEmpty) {
            scheduleParts.add(scheduleDate);
          }
          if (scheduleTime != null && scheduleTime.isNotEmpty) {
            scheduleParts.add(scheduleTime);
          }
          final scheduleLabel = scheduleParts.isNotEmpty
              ? scheduleParts.join(' ')
              : 'Schedule TBD';
          final featuresValue = course['features'];
          String featuresLabel = '';
          if (featuresValue is List) {
            featuresLabel = featuresValue.map((e) => e.toString()).join(', ');
          } else if (featuresValue is String) {
            featuresLabel = featuresValue;
          }
          return {
            'title': course['title']?.toString() ?? 'Untitled course',
            'level': course['category']?.toString() ?? 'General',
            'mentor': course['instructorName']?.toString() ?? 'Unknown instructor',
            'weeks': durationLabel,
            'students': '0 students',
            'rating': '0.0',
            'status': 'Active',
            'schedule': scheduleLabel,
            'features': featuresLabel,
          };
        }).toList();
        setState(() {
          _courses = mapped;
        });
      } else {
        setState(() {
          _courses = [];
          _errorMessage = 'Unexpected response format.';
        });
      }
    } on HttpException catch (err) {
      setState(() {
        _errorMessage = err.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to load courses. Please try again.';
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
    final courses = _courses.isNotEmpty
        ? _courses
        : List<Map<String, String>>.generate(0, (_) => {});

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
            'My Courses',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.teacherPrimaryDark,
              fontFamily: 'Inter',
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.teacherPrimary),
              onPressed: _openCreateCourse,
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  PrimaryButton(
                    text: 'Create course',
                    height: 44,
                    onPressed: _openCreateCourse,
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
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
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ...courses.map(
                    (course) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.teacherSurface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.teacherChip,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.play_lesson,
                              color: AppColors.teacherPrimaryDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course['title']!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${course['level']} - ${course['mentor']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.teacherMuted,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${course['students']} - ${course['rating']} rating - ${course['weeks']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.teacherMuted,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  course['schedule'] ?? 'Schedule TBD',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.teacherMuted,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                if ((course['features'] ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    course['features']!,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.teacherMuted,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.teacherChip,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              course['status']!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.teacherPrimaryDark,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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


