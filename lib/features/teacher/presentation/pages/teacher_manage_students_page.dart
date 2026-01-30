import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';

class TeacherManageStudentsPage extends StatefulWidget {
  const TeacherManageStudentsPage({Key? key}) : super(key: key);

  @override
  State<TeacherManageStudentsPage> createState() => _TeacherManageStudentsPageState();
}

class _TeacherManageStudentsPageState extends State<TeacherManageStudentsPage> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  String? _errorMessage;
  final List<_StudentItem> _students = [];
  final List<_TeacherRequestItem> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _loadStudents(),
        _loadRequests(),
      ]);
    } on HttpException catch (err) {
      if (mounted) {
        setState(() {
          _errorMessage = err.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load students.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStudents() async {
    final response = await _apiClient.getJson(
      '/api/v1/teacher-requests',
      token: HiveService.authToken,
    );
    final data = response['data'];
    if (data is! List) {
      return;
    }
    final mapped = data
        .whereType<Map<String, dynamic>>()
        .map(_TeacherRequestItem.fromJson)
        .where((item) => item.status == 'accepted')
        .map(
          (request) => _StudentItem(
            id: request.id,
            name: request.studentName,
            course: request.courseTitle,
            status: 'Active',
          ),
        )
        .toList();
    _students
      ..clear()
      ..addAll(mapped);
  }

  Future<void> _loadRequests() async {
    final response = await _apiClient.getJson(
      '/api/v1/teacher-requests',
      token: HiveService.authToken,
    );
    final data = response['data'];
    if (data is! List) {
      return;
    }
    final mapped = data
        .whereType<Map<String, dynamic>>()
        .map(_TeacherRequestItem.fromJson)
        .where((item) => item.status == 'pending')
        .toList();
    _requests
      ..clear()
      ..addAll(mapped);
  }

  Future<void> _updateRequestStatus(_TeacherRequestItem request, String status) async {
    try {
      await _apiClient.putJson(
        '/api/v1/teacher-requests/${request.id}',
        token: HiveService.authToken,
        body: {'status': status},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _requests.removeWhere((item) => item.id == request.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $status.')),
      );
      await _loadStudents();
      if (mounted) {
        setState(() {});
      }
    } on HttpException catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update request.')),
        );
      }
    }
  }

  Future<void> _deleteRequest(_TeacherRequestItem request) async {
    try {
      await _apiClient.deleteJson(
        '/api/v1/teacher-requests/${request.id}',
        token: HiveService.authToken,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _requests.removeWhere((item) => item.id == request.id);
      });
    } on HttpException catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to delete request.')),
        );
      }
    }
  }

  Future<void> _clearAllRequests() async {
    if (_requests.isEmpty) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all requests?'),
        content: const Text('This will remove all pending student requests.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teacherPrimary,
              foregroundColor: AppColors.buttonText,
            ),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final pending = List<_TeacherRequestItem>.from(_requests);
    for (final request in pending) {
      await _deleteRequest(request);
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
          'Manage Students',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          if (_requests.isNotEmpty)
            TextButton(
              onPressed: _clearAllRequests,
              child: const Text('Clear all'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const Text(
            'Student requests',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
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
                  fontFamily: 'Inter',
                ),
              ),
            ),
          if (!_isLoading && _errorMessage == null && _requests.isEmpty)
            const Text(
              'No requests yet.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ..._requests.map(
            (request) => Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.studentName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    request.courseTitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _updateRequestStatus(request, 'rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            side: const BorderSide(color: AppColors.divider),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Decline'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateRequestStatus(request, 'accepted'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teacherPrimary,
                            foregroundColor: AppColors.buttonText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Accept'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => _deleteRequest(request),
                        icon: const Icon(Icons.delete_outline),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Active learners',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          ..._students.map(
            (student) => Container(
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
                          fontFamily: 'Inter',
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
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          student.course,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      student.statusLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
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
    );
  }
}

class _StudentItem {
  final String id;
  final String name;
  final String course;
  final String status;

  const _StudentItem({
    required this.id,
    required this.name,
    required this.course,
    required this.status,
  });

  String get statusLabel {
    if (status == 'inactive') {
      return 'Inactive';
    }
    if (status == 'requested') {
      return 'Requested';
    }
    return 'Active';
  }
}

class _TeacherRequestItem {
  final String id;
  final String studentName;
  final String courseTitle;
  final String status;

  const _TeacherRequestItem({
    required this.id,
    required this.studentName,
    required this.courseTitle,
    required this.status,
  });

  static _TeacherRequestItem fromJson(Map<String, dynamic> json) {
    final student = json['student'];
    final course = json['course'];
    return _TeacherRequestItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      studentName: student is Map<String, dynamic>
          ? student['name']?.toString() ?? 'Student'
          : 'Student',
      courseTitle: course is Map<String, dynamic>
          ? course['title']?.toString() ?? 'Course'
          : 'Course',
      status: json['status']?.toString() ?? 'pending',
    );
  }
}

