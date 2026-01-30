import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';

class TeacherRequestsPage extends StatefulWidget {
  const TeacherRequestsPage({Key? key}) : super(key: key);

  @override
  State<TeacherRequestsPage> createState() => _TeacherRequestsPageState();
}

class _TeacherRequestsPageState extends State<TeacherRequestsPage> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  String? _errorMessage;
  List<_TeacherRequestItem> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'Please log in to view requests.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getJson(
        '/api/v1/teacher-requests',
        token: token,
      );
      final data = response['data'];
      if (data is List) {
        final mapped = data
            .whereType<Map<String, dynamic>>()
            .map(_TeacherRequestItem.fromJson)
            .toList();
        setState(() {
          _requests = mapped;
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
        _errorMessage = 'Unable to load requests.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateStatus(_TeacherRequestItem request, String status) async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      return;
    }
    try {
      await _apiClient.putJson(
        '/api/v1/teacher-requests/${request.id}',
        token: token,
        body: {'status': status},
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _requests = _requests
            .map((item) => item.id == request.id
                ? item.copyWith(status: status)
                : item)
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request $status.')),
      );
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
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      return;
    }
    try {
      await _apiClient.deleteJson(
        '/api/v1/teacher-requests/${request.id}',
        token: token,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _requests = _requests.where((item) => item.id != request.id).toList();
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
    final items = List<_TeacherRequestItem>.from(_requests);
    for (final request in items) {
      await _deleteRequest(request);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          'Review Requests',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.teacherPrimaryDark,
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
            'New requests',
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
                color: AppColors.teacherSurface,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${request.courseTitle} · ${request.createdLabel}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.teacherMuted,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: request.isPending
                              ? () => _updateStatus(request, 'rejected')
                              : null,
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
                          onPressed: request.isPending
                              ? () => _updateStatus(request, 'accepted')
                              : null,
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
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _deleteRequest(request),
                        icon: const Icon(Icons.delete_outline),
                        color: AppColors.teacherMuted,
                      ),
                    ],
                  ),
                  if (!request.isPending) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Status: ${request.statusLabel}',
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
          ),
        ],
      ),
    );
  }
}

class _TeacherRequestItem {
  final String id;
  final String studentName;
  final String courseTitle;
  final String status;
  final DateTime createdAt;

  const _TeacherRequestItem({
    required this.id,
    required this.studentName,
    required this.courseTitle,
    required this.status,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';

  String get statusLabel {
    switch (status) {
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  String get createdLabel {
    final local = createdAt.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.month}/${local.day} $hour:$minute';
  }

  _TeacherRequestItem copyWith({String? status}) {
    return _TeacherRequestItem(
      id: id,
      studentName: studentName,
      courseTitle: courseTitle,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

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
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

