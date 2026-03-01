import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';

class TeacherStudentLoginsPage extends StatefulWidget {
  const TeacherStudentLoginsPage({Key? key}) : super(key: key);

  @override
  State<TeacherStudentLoginsPage> createState() => _TeacherStudentLoginsPageState();
}

class _TeacherStudentLoginsPageState extends State<TeacherStudentLoginsPage> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  String? _errorMessage;
  final List<_StudentLoginItem> _students = [];

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    _setStateIfMounted(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getJson(
        '/api/v1/teacher-requests',
        token: HiveService.authToken,
      );
      final data = response['data'];
      if (data is List) {
        final mapped = data
            .whereType<Map<String, dynamic>>()
            .map(_StudentLoginItem.fromRequest)
            .where((item) => item.status == 'Accepted')
            .toList();
        _setStateIfMounted(() {
          _students
            ..clear()
            ..addAll(mapped);
        });
      } else {
        _setStateIfMounted(() {
          _errorMessage = 'Unexpected response format.';
        });
      }
    } on HttpException catch (err) {
      _setStateIfMounted(() {
        _errorMessage = err.message;
      });
    } catch (_) {
      _setStateIfMounted(() {
        _errorMessage = 'Unable to load student logins.';
      });
    } finally {
      _setStateIfMounted(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.teacherHome,
            (route) => false,
          ),
        ),
        title: const Text(
          'Student Logins',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
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
          if (!_isLoading && _errorMessage == null && _students.isEmpty)
            const Text(
              'No accepted requests yet.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'OpenSans',
              ),
            ),
          ..._students.map(
            (student) => GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.teacherStudentProfile,
                  arguments: student.toMap(),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(18),
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.categoryPurple,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          student.name.substring(0, 1),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            student.course,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          student.lastActive,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            student.status,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentLoginItem {
  final String name;
  final String course;
  final String status;
  final String lastActive;

  const _StudentLoginItem({
    required this.name,
    required this.course,
    required this.status,
    required this.lastActive,
  });

  static _StudentLoginItem fromRequest(Map<String, dynamic> json) {
    final student = json['student'];
    final studentMap = student is Map<String, dynamic> ? student : <String, dynamic>{};
    final course = json['course'];
    final courseMap = course is Map<String, dynamic> ? course : <String, dynamic>{};
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    return _StudentLoginItem(
      name: studentMap['name']?.toString() ?? 'Student',
      course: courseMap['title']?.toString() ?? 'Course',
      status: json['status']?.toString() == 'accepted' ? 'Accepted' : 'Pending',
      lastActive: createdAt == null ? 'Accepted' : _formatDate(createdAt),
    );
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'course': course,
      'status': status,
      'lastActive': lastActive,
    };
  }
}



