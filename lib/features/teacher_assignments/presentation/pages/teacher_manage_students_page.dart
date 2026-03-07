import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/services/socket/socket_service.dart';
import '../../../../core/services/teacher/teacher_request_actions_service.dart';

class TeacherManageStudentsPage extends StatefulWidget {
  const TeacherManageStudentsPage({Key? key}) : super(key: key);

  @override
  State<TeacherManageStudentsPage> createState() => _TeacherManageStudentsPageState();
}

class _TeacherManageStudentsPageState extends State<TeacherManageStudentsPage> {
  final ApiClient _apiClient = ApiClient();
  final TeacherRequestActionsService _requestActions =
      TeacherRequestActionsService();
  final SocketService _socketService = SocketService();
  Timer? _pollTimer;
  bool _isFetching = false;
  final Set<String> _mutatingRequestIds = <String>{};
  bool _isLoading = false;
  String? _errorMessage;
  final List<_StudentItem> _students = [];
  final List<_TeacherRequestItem> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadData(showLoading: true);
    _startPolling();
    _initSocket();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadData(showLoading: false);
    });
  }

  void _initSocket() {
    _socketService.connect();
    _socketService.joinUser();
    _socketService.onNotificationNew(_handleNotificationNew);
  }

  void _handleNotificationNew(dynamic payload) {
    if (!mounted) {
      return;
    }
    _loadData(showLoading: false);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _socketService.offNotificationNew(_handleNotificationNew);
    super.dispose();
  }

  Future<void> _loadData({required bool showLoading}) async {
    if (_isFetching) {
      return;
    }
    _isFetching = true;
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

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
      _isFetching = false;
      if (mounted) {
        setState(() {
          if (showLoading) {
            _isLoading = false;
          }
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
    final accepted = data
        .whereType<Map<String, dynamic>>()
        .map(_TeacherRequestItem.fromJson)
        .where((item) => item.normalizedStatus == 'accepted' && !item.isDeleted)
        .toList();

    final unique = <String, _StudentItem>{};
    for (final request in accepted) {
      final key = '${request.studentId}::${request.courseId}::${request.courseTitle.toLowerCase()}';
      unique[key] = _StudentItem(
        id: request.studentId.isNotEmpty ? request.studentId : request.id,
        name: request.studentName,
        course: request.courseTitle,
        status: 'Active',
      );
    }
    final mapped = unique.values.toList();
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
    final pending = data
        .whereType<Map<String, dynamic>>()
        .map(_TeacherRequestItem.fromJson)
        .where((item) => item.isPending && !item.isDeleted)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final unique = <String, _TeacherRequestItem>{};
    for (final request in pending) {
      final key = '${request.studentId}::${request.courseId}::${request.courseTitle.toLowerCase()}';
      final existing = unique[key];
      if (existing == null || request.createdAt.isAfter(existing.createdAt)) {
        unique[key] = request;
      }
    }
    final mapped = unique.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _requests
      ..clear()
      ..addAll(mapped);
  }

  Future<void> _updateRequestStatus(_TeacherRequestItem request, String status) async {
    if (_mutatingRequestIds.contains(request.id)) {
      return;
    }
    setState(() {
      _mutatingRequestIds.add(request.id);
    });
    try {
      await _requestActions.updateStatus(
        requestId: request.id,
        status: status,
        token: HiveService.authToken ?? '',
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
      await _loadData(showLoading: false);
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
    } finally {
      if (mounted) {
        setState(() {
          _mutatingRequestIds.remove(request.id);
        });
      }
    }
  }

  Future<void> _deleteRequest(_TeacherRequestItem request) async {
    if (_mutatingRequestIds.contains(request.id)) {
      return;
    }
    setState(() {
      _mutatingRequestIds.add(request.id);
    });
    try {
      await _requestActions.deleteRequest(
        requestId: request.id,
        token: HiveService.authToken ?? '',
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
    } finally {
      if (mounted) {
        setState(() {
          _mutatingRequestIds.remove(request.id);
        });
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
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      return;
    }

    try {
      await _requestActions.clearAllRequests(token: token);
      if (!mounted) {
        return;
      }
      setState(() {
        _requests.clear();
      });
    } on HttpException catch (_) {
      final pending = List<_TeacherRequestItem>.from(_requests);
      for (final request in pending) {
        await _deleteRequest(request);
      }
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
            fontFamily: 'OpenSans',
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
              fontFamily: 'OpenSans',
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
                  fontFamily: 'OpenSans',
                ),
              ),
            ),
          if (!_isLoading && _errorMessage == null && _requests.isEmpty)
            const Text(
              'No requests yet.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'OpenSans',
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
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    request.courseTitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _mutatingRequestIds.contains(request.id)
                              ? null
                              : () => _updateRequestStatus(request, 'rejected'),
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
                          onPressed: _mutatingRequestIds.contains(request.id)
                              ? null
                              : () => _updateRequestStatus(request, 'accepted'),
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
                        onPressed: _mutatingRequestIds.contains(request.id)
                            ? null
                            : () => _deleteRequest(request),
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
              fontFamily: 'OpenSans',
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
                        fontFamily: 'OpenSans',
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
  final String studentId;
  final String courseId;
  final String studentName;
  final String courseTitle;
  final String status;
  final DateTime createdAt;
  final bool isDeleted;

  const _TeacherRequestItem({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.studentName,
    required this.courseTitle,
    required this.status,
    required this.createdAt,
    required this.isDeleted,
  });

  String get normalizedStatus => status.trim().toLowerCase();
  bool get isPending => normalizedStatus == 'pending';

  static _TeacherRequestItem fromJson(Map<String, dynamic> json) {
    final student = json['student'];
    final course = json['course'];
    final studentMap =
        student is Map<String, dynamic> ? student : <String, dynamic>{};
    final courseMap = course is Map<String, dynamic> ? course : <String, dynamic>{};
    final studentId = studentMap['_id']?.toString() ??
        studentMap['id']?.toString() ??
        json['studentId']?.toString() ??
        '';
    final courseId = courseMap['_id']?.toString() ??
        courseMap['id']?.toString() ??
        json['courseId']?.toString() ??
        '';
    final createdRaw = json['createdAt']?.toString() ??
        json['updatedAt']?.toString() ??
        '';
    return _TeacherRequestItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      studentId: studentId,
      courseId: courseId,
      studentName: student is Map<String, dynamic>
          ? student['name']?.toString() ?? 'Student'
          : 'Student',
      courseTitle: course is Map<String, dynamic>
          ? course['title']?.toString() ?? 'Course'
          : 'Course',
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(createdRaw) ?? DateTime.now(),
      isDeleted: json['isDeleted'] == true ||
          json['deleted'] == true ||
          (json['status']?.toString().toLowerCase() == 'deleted'),
    );
  }
}



