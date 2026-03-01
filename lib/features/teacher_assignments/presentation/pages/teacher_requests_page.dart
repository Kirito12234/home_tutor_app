import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/services/teacher/teacher_request_actions_service.dart';

class TeacherRequestsPage extends StatefulWidget {
  const TeacherRequestsPage({Key? key}) : super(key: key);

  @override
  State<TeacherRequestsPage> createState() => _TeacherRequestsPageState();
}

class _TeacherRequestsPageState extends State<TeacherRequestsPage> {
  final ApiClient _apiClient = ApiClient();
  final TeacherRequestActionsService _requestActions =
      TeacherRequestActionsService();
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
            .where((item) => !item.isDeleted)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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
      await _requestActions.updateStatus(
        requestId: request.id,
        status: status,
        token: token,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _requests = _requests
            .map((item) =>
                item.id == request.id ? item.copyWith(status: status) : item)
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
      await _requestActions.deleteRequest(
        requestId: request.id,
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
      final items = List<_TeacherRequestItem>.from(_requests);
      for (final request in items) {
        await _deleteRequest(request);
      }
    }
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

  Future<void> _viewRequestScreenshot(_TeacherRequestItem request) async {
    final raw = request.proofImageUrl;
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No screenshot uploaded by student yet.')),
      );
      return;
    }
    final imageUrl = _assetUrl(raw);
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Unable to preview image.'),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        final uri = Uri.tryParse(imageUrl);
                        if (uri == null) {
                          return;
                        }
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                      child: const Text('Open externally'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.teacherBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: AppColors.teacherPrimaryDark),
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
            'New requests',
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
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${request.courseTitle} · ${request.createdLabel}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.teacherMuted,
                      fontFamily: 'OpenSans',
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
                      OutlinedButton(
                        onPressed: request.proofImageUrl.isEmpty
                            ? null
                            : () => _viewRequestScreenshot(request),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('View'),
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
                        fontFamily: 'OpenSans',
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
  final bool isDeleted;
  final String proofImageUrl;

  const _TeacherRequestItem({
    required this.id,
    required this.studentName,
    required this.courseTitle,
    required this.status,
    required this.createdAt,
    required this.isDeleted,
    required this.proofImageUrl,
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
      isDeleted: isDeleted,
      proofImageUrl: proofImageUrl,
    );
  }

  static _TeacherRequestItem fromJson(Map<String, dynamic> json) {
    final student = json['student'];
    final course = json['course'];
    final payment = json['payment'];
    final paymentMap = payment is Map
        ? Map<String, dynamic>.from(payment)
        : <String, dynamic>{};
    final proof = json['proof'];
    final proofMap =
        proof is Map ? Map<String, dynamic>.from(proof) : <String, dynamic>{};
    final screenshot = json['screenshot'];
    final screenshotMap = screenshot is Map
        ? Map<String, dynamic>.from(screenshot)
        : <String, dynamic>{};
    final attachments = json['attachments'];
    final attachmentList = attachments is List
        ? attachments
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];
    final firstAttachment =
        attachmentList.isNotEmpty ? attachmentList.first : <String, dynamic>{};
    final proofImageUrl = _firstNonEmptyString(
      <dynamic>[
        json['screenshotUrl'],
        json['paymentScreenshotUrl'],
        json['paymentProofUrl'],
        json['proofImageUrl'],
        json['proofUrl'],
        json['receiptImageUrl'],
        json['imageUrl'],
        json['fileUrl'],
        paymentMap['screenshotUrl'],
        paymentMap['paymentScreenshotUrl'],
        paymentMap['proofImageUrl'],
        paymentMap['receiptImageUrl'],
        paymentMap['imageUrl'],
        paymentMap['fileUrl'],
        proofMap['url'],
        proofMap['imageUrl'],
        proofMap['fileUrl'],
        screenshotMap['url'],
        screenshotMap['imageUrl'],
        screenshotMap['fileUrl'],
        firstAttachment['url'],
        firstAttachment['imageUrl'],
        firstAttachment['fileUrl'],
      ],
    );
    final studentName = _firstNonEmptyString(<dynamic>[
      json['studentName'],
      json['name'],
      if (student is Map<String, dynamic>) student['name'],
      if (student is Map<String, dynamic>) student['fullName'],
    ]);
    final courseTitle = _firstNonEmptyString(<dynamic>[
      json['courseTitle'],
      if (course is Map<String, dynamic>) course['title'],
      json['courseName'],
    ]);
    return _TeacherRequestItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      studentName: studentName.isEmpty ? 'Student' : studentName,
      courseTitle: courseTitle.isEmpty ? 'Course' : courseTitle,
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      isDeleted: json['isDeleted'] == true ||
          json['deleted'] == true ||
          (json['status']?.toString().toLowerCase() == 'deleted'),
      proofImageUrl: proofImageUrl,
    );
  }

  static String _firstNonEmptyString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return '';
  }
}
