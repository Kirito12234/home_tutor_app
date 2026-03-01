import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/utils/file_download.dart';
import '../../../../core/widgets/file_picker_screen.dart';
import '../../../../core/widgets/pdf_viewer_page.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/video_viewer_page.dart';
import '../../domain/entities/course.dart';
import '../widgets/lesson_list_item.dart';
import '../../../student_dashboard/domain/entities/lesson.dart';

class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({Key? key}) : super(key: key);

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

enum _StudentPaymentMethod {
  eSewa,
  khalti,
  imePay,
  bankTransfer;

  String get label {
    switch (this) {
      case _StudentPaymentMethod.eSewa:
        return 'eSewa';
      case _StudentPaymentMethod.khalti:
        return 'Khalti';
      case _StudentPaymentMethod.imePay:
        return 'IME Pay';
      case _StudentPaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  String get apiValue {
    switch (this) {
      case _StudentPaymentMethod.eSewa:
        return 'esewa';
      case _StudentPaymentMethod.khalti:
        return 'khalti';
      case _StudentPaymentMethod.imePay:
        return 'ime_pay';
      case _StudentPaymentMethod.bankTransfer:
        return 'bank_transfer';
    }
  }

  List<String> get keyCandidates {
    switch (this) {
      case _StudentPaymentMethod.eSewa:
        return const [
          'esewa',
          'eSewa',
          'esewaQr',
          'esewaQR',
          'esewaQrUrl',
          'esewaImage',
          'esewaImageUrl',
        ];
      case _StudentPaymentMethod.khalti:
        return const [
          'khalti',
          'khaltiQr',
          'khaltiQR',
          'khaltiQrUrl',
          'khaltiImage',
          'khaltiImageUrl',
        ];
      case _StudentPaymentMethod.imePay:
        return const [
          'imePay',
          'ime',
          'imePayQr',
          'imepayQr',
          'imeQr',
          'imePayQrUrl',
          'imePayImage',
          'imePayImageUrl',
        ];
      case _StudentPaymentMethod.bankTransfer:
        return const [
          'bank',
          'bankTransfer',
          'bankQr',
          'bankImage',
          'bankTransferQr',
          'bankTransferImage',
          'bankTransferImageUrl',
          'bankReceiptImage',
        ];
    }
  }

  Color get previewColor {
    switch (this) {
      case _StudentPaymentMethod.eSewa:
        return const Color(0xFF1D7E5B);
      case _StudentPaymentMethod.khalti:
        return const Color(0xFF0B1638);
      case _StudentPaymentMethod.imePay:
        return const Color(0xFF1A3F8B);
      case _StudentPaymentMethod.bankTransfer:
        return const Color(0xFF2B4B66);
    }
  }

  IconData get fallbackIcon {
    switch (this) {
      case _StudentPaymentMethod.eSewa:
        return Icons.qr_code_2;
      case _StudentPaymentMethod.khalti:
        return Icons.qr_code;
      case _StudentPaymentMethod.imePay:
        return Icons.account_balance_wallet;
      case _StudentPaymentMethod.bankTransfer:
        return Icons.account_balance;
    }
  }
}

class _AccessState {
  const _AccessState({
    required this.isApproved,
    required this.isPending,
  });

  final bool isApproved;
  final bool isPending;
}

enum _CourseMaterialType { video, pdf, image, other }

class _CourseMaterialItem {
  const _CourseMaterialItem({
    required this.title,
    required this.url,
    required this.type,
    required this.lessonTitle,
  });

  final String title;
  final String url;
  final _CourseMaterialType type;
  final String lessonTitle;
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final ApiClient _apiClient = ApiClient();
  Course? _course;
  List<Lesson> _lessons = [];
  String? _courseCoverUrl;
  String? _teacherImageUrl;
  bool _isLoading = false;
  bool _isRequesting = false;
  bool _isCheckingAccess = false;
  bool _isSubmittingPayment = false;
  bool _hasAccess = true;
  bool _isApprovalPending = false;
  String? _paymentStatusMessage;
  SelectedFile? _paymentScreenshot;
  String? _errorMessage;
  bool _didLoad = false;
  Timer? _accessPollTimer;
  _StudentPaymentMethod _selectedPaymentMethod = _StudentPaymentMethod.khalti;
  Map<_StudentPaymentMethod, String> _teacherQrByMethod = {};
  bool _isFavorite = false;
  bool _isFavoriteBusy = false;
  List<_CourseMaterialItem> _materials = <_CourseMaterialItem>[];

  bool get _isStudent =>
      HiveService.currentUserRole?.toLowerCase() == 'student';
  bool get _isLockedForStudent => _isStudent && !_hasAccess;

  String _formatPrice(double price) {
    return 'RS ${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) {
      return;
    }
    _didLoad = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! Course) {
      setState(() {
        _course = null;
      });
      return;
    }
    setState(() {
      _course = args;
      _courseCoverUrl = _assetUrl(args.imageUrl);
    });
    _loadFavoriteStatus(args.id);
    _loadLessons(args.id);
    _loadTeacherPayoutDetails(args.id);
    _checkStudentAccess(args);
  }

  @override
  void dispose() {
    _accessPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStudentAccess(Course course) async {
    if (!_isStudent) {
      setState(() {
        _hasAccess = true;
        _isApprovalPending = false;
        _paymentStatusMessage = null;
      });
      return;
    }

    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _hasAccess = false;
        _isApprovalPending = false;
        _paymentStatusMessage = null;
      });
      return;
    }

    setState(() {
      _isCheckingAccess = true;
    });

    try {
      final access = await _resolveAccessState(course.id, token);
      final wasLocked = _isLockedForStudent;

      setState(() {
        _hasAccess = access.isApproved;
        _isApprovalPending = access.isPending;
        _paymentStatusMessage = access.isApproved
            ? 'Payment approved. Course unlocked.'
            : (access.isPending
                ? 'Payment submitted. Approval pending.'
                : null);
      });
      if (access.isApproved) {
        _accessPollTimer?.cancel();
        _accessPollTimer = null;
        if (wasLocked && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment approved. Course unlocked.')),
          );
          if (_lessons.isNotEmpty) {
            _openFirstLesson(course);
          }
        }
      } else {
        _startAccessPolling(course);
      }
    } catch (_) {
      // Default to locked state for students if status cannot be resolved.
      setState(() {
        _hasAccess = false;
      });
      _startAccessPolling(course);
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAccess = false;
        });
      }
    }
  }

  Future<_AccessState> _resolveAccessState(
      String courseId, String token) async {
    final statusPaths = <String>[
      '/api/v1/payments/status/$courseId',
      '/api/v1/payments/$courseId/status',
      '/api/v1/enrollments/$courseId/status',
    ];

    for (final path in statusPaths) {
      try {
        final response = await _apiClient.getJson(path, token: token);
        final payload = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        final resolved = _parseAccessPayload(payload);
        if (resolved != null) {
          return resolved;
        }
      } on HttpException catch (err) {
        if (err.statusCode == 404 || err.statusCode == 405) {
          continue;
        }
      } catch (_) {}
    }

    return _resolveAccessFromEnrollments(courseId, token);
  }

  _AccessState? _parseAccessPayload(Map<String, dynamic> payload) {
    final statusValues = <String>[
      payload['status']?.toString() ?? '',
      payload['paymentStatus']?.toString() ?? '',
      payload['approvalStatus']?.toString() ?? '',
      payload['accessStatus']?.toString() ?? '',
    ];
    for (final value in statusValues) {
      final normalized = value.toLowerCase().trim();
      if (_isApprovedStatus(normalized)) {
        return const _AccessState(isApproved: true, isPending: false);
      }
      if (_isPendingStatus(normalized)) {
        return const _AccessState(isApproved: false, isPending: true);
      }
    }
    if (payload['isApproved'] == true ||
        payload['approved'] == true ||
        payload['hasAccess'] == true) {
      return const _AccessState(isApproved: true, isPending: false);
    }
    return null;
  }

  Future<_AccessState> _resolveAccessFromEnrollments(
    String courseId,
    String token,
  ) async {
    final response = await _apiClient.getJson(
      '/api/v1/enrollments',
      token: token,
    );
    final data = response['data'];
    if (data is! List) {
      return const _AccessState(isApproved: false, isPending: false);
    }

    for (final row in data.whereType<Map<String, dynamic>>()) {
      final courseRaw = row['course'];
      String rowCourseId = '';
      if (courseRaw is Map<String, dynamic>) {
        rowCourseId =
            courseRaw['_id']?.toString() ?? courseRaw['id']?.toString() ?? '';
      } else {
        rowCourseId = row['courseId']?.toString() ?? '';
      }
      if (rowCourseId != courseId) {
        continue;
      }
      final status = row['status']?.toString().toLowerCase() ?? '';
      if (_isApprovedStatus(status) ||
          row['isApproved'] == true ||
          row['approved'] == true) {
        return const _AccessState(isApproved: true, isPending: false);
      }
      if (_isPendingStatus(status)) {
        return const _AccessState(isApproved: false, isPending: true);
      }
    }
    return const _AccessState(isApproved: false, isPending: false);
  }

  bool _isApprovedStatus(String status) {
    return status == 'approved' ||
        status == 'paid' ||
        status == 'completed' ||
        status == 'active' ||
        status == 'accepted';
  }

  bool _isPendingStatus(String status) {
    return status == 'pending' ||
        status == 'submitted' ||
        status == 'under_review' ||
        status == 'review';
  }

  void _startAccessPolling(Course course) {
    if (!_isStudent || _hasAccess) {
      return;
    }
    _accessPollTimer ??= Timer.periodic(
      const Duration(seconds: 8),
      (_) {
        if (!mounted) {
          return;
        }
        _checkStudentAccess(course);
      },
    );
  }

  Future<void> _loadLessons(String courseId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      List<dynamic>? rawLessons;
      try {
        final response =
            await _apiClient.getJson('/api/v1/courses/$courseId/lessons');
        final data = response['data'];
        if (data is List) {
          rawLessons = data;
        }
      } on HttpException {
        final courseResponse =
            await _apiClient.getJson('/api/v1/courses/$courseId');
        final courseData = courseResponse['data'];
        if (courseData is Map<String, dynamic> &&
            courseData['lessons'] is List) {
          rawLessons = courseData['lessons'] as List;
        }
      }

      if (rawLessons == null) {
        setState(() {
          _errorMessage = 'Unexpected response format.';
        });
        return;
      }

      final lessonMaps = rawLessons.whereType<Map<String, dynamic>>().toList();
      final mapped = lessonMaps.map((lesson) {
        final status = lesson['status']?.toString().toLowerCase() ?? '';
        return Lesson(
          id: lesson['_id']?.toString() ?? lesson['id']?.toString() ?? 'lesson',
          title: lesson['title']?.toString() ?? 'Lesson',
          durationMinutes: (lesson['durationMinutes'] as num?)?.toInt() ?? 0,
          isCompleted: lesson['isCompleted'] == true ||
              lesson['completed'] == true ||
              status == 'completed',
          isLocked: lesson['isLocked'] == true,
          order: (lesson['order'] as num?)?.toInt() ?? 0,
          imageUrl: lesson['imageUrl']?.toString(),
          pdfUrl: lesson['pdfUrl']?.toString(),
        );
      }).toList();
      final materials = <_CourseMaterialItem>[];
      for (final lesson in lessonMaps) {
        materials.addAll(_extractLessonMaterials(lesson));
      }
      final coverUrl = _assetUrl(_courseCoverUrl ?? _course?.imageUrl);
      if (coverUrl.isNotEmpty &&
          !materials.any((item) => item.url == coverUrl)) {
        materials.insert(
          0,
          _CourseMaterialItem(
            title: 'Course cover image',
            url: coverUrl,
            type: _CourseMaterialType.image,
            lessonTitle: 'Course',
          ),
        );
      }
      setState(() {
        _lessons = mapped;
        _materials = materials;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to load lessons.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendTeacherRequest(Course course) async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send request.')),
      );
      Navigator.of(context).pushNamed(AppRoutes.login);
      return;
    }
    if (course.tutorId == null || course.tutorId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher information is missing.')),
      );
      return;
    }

    setState(() {
      _isRequesting = true;
    });

    try {
      await _apiClient.postJson(
        '/api/v1/teacher-requests',
        token: token,
        body: {
          'course': course.id,
          'tutor': course.tutorId,
          'message': 'Request to join course.',
        },
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent to teacher.')),
      );
    } on HttpException catch (err) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to send request.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  Future<void> _loadTeacherPayoutDetails(String courseId) async {
    try {
      final token = HiveService.authToken;
      final response = await _apiClient.getJson(
        '/api/v1/courses/$courseId',
        token: token,
      );
      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        return;
      }
      final methods = _extractTeacherQrMethods(data);
      final latestCourseCoverUrl = _extractCourseImageUrl(data);
      final latestTeacherImageUrl = _extractTeacherImageUrl(data);
      final tutorRaw = data['tutor'];
      final tutorIdFromCourse =
          tutorRaw is Map<String, dynamic> ? tutorRaw['_id']?.toString() : null;
      final tutorId =
          (tutorIdFromCourse != null && tutorIdFromCourse.isNotEmpty)
              ? tutorIdFromCourse
              : (_course?.tutorId ?? '');
      Map<_StudentPaymentMethod, String> payoutMethods = {};
      if (tutorId.isNotEmpty) {
        payoutMethods = await _loadPayoutSettingsByTutor(tutorId, token);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _teacherQrByMethod = {
          ...methods,
          ...payoutMethods,
        };
        if (latestCourseCoverUrl.isNotEmpty) {
          _courseCoverUrl = _assetUrl(latestCourseCoverUrl);
        }
        if (latestTeacherImageUrl.isNotEmpty) {
          _teacherImageUrl = _assetUrl(latestTeacherImageUrl);
        }
      });
    } catch (_) {
      // If payout details are unavailable, student can still submit screenshot.
    }
  }

  Future<Map<_StudentPaymentMethod, String>> _loadPayoutSettingsByTutor(
    String tutorId,
    String? token,
  ) async {
    final response = await _apiClient.getJson(
      '/api/v1/payout-settings/tutor/$tutorId',
      token: token,
    );
    final data = response['data'];
    if (data is! List) {
      return <_StudentPaymentMethod, String>{};
    }
    final methods = <_StudentPaymentMethod, String>{};
    for (final row in data.whereType<Map>()) {
      final map = Map<String, dynamic>.from(row);
      final method = _studentMethodFromRaw(map['method']?.toString());
      if (method == null) {
        continue;
      }
      final detailsRaw = map['details'];
      final details = detailsRaw is Map<String, dynamic>
          ? detailsRaw
          : (detailsRaw is Map
              ? Map<String, dynamic>.from(detailsRaw)
              : <String, dynamic>{});
      final url = _assetUrl(
        details['qrImageUrl']?.toString() ??
            details['qrUrl']?.toString() ??
            details['imageUrl']?.toString() ??
            details['url']?.toString() ??
            map['qrImageUrl']?.toString() ??
            map['qrUrl']?.toString() ??
            map['imageUrl']?.toString() ??
            map['url']?.toString(),
      );
      if (url.isEmpty) {
        continue;
      }
      methods[method] = url;
    }
    return methods;
  }

  _StudentPaymentMethod? _studentMethodFromRaw(String? value) {
    final raw = (value ?? '').trim().toLowerCase();
    switch (raw) {
      case 'esewa':
      case 'e-sewa':
        return _StudentPaymentMethod.eSewa;
      case 'khalti':
        return _StudentPaymentMethod.khalti;
      case 'ime':
      case 'imepay':
      case 'ime_pay':
      case 'ime pay':
        return _StudentPaymentMethod.imePay;
      case 'bank':
      case 'banktransfer':
      case 'bank_transfer':
      case 'bank transfer':
        return _StudentPaymentMethod.bankTransfer;
      default:
        return null;
    }
  }

  String _extractCourseImageUrl(Map<String, dynamic> source) {
    final direct = _firstNonEmptyString(source, const [
      'imageUrl',
      'image',
      'thumbnail',
      'thumbnailUrl',
      'coverImage',
      'coverImageUrl',
      'banner',
      'bannerUrl',
    ]);
    if (direct != null) {
      return direct;
    }
    final data = source['data'];
    if (data is Map<String, dynamic>) {
      return _extractCourseImageUrl(data);
    }
    return '';
  }

  String _extractTeacherImageUrl(Map<String, dynamic> source) {
    final tutorRaw =
        source['tutor'] ?? source['teacher'] ?? source['instructor'];
    if (tutorRaw is Map<String, dynamic>) {
      final tutorImage = _firstNonEmptyString(tutorRaw, const [
        'imageUrl',
        'avatarUrl',
        'photoUrl',
        'profileImage',
        'avatar',
        'image',
      ]);
      if (tutorImage != null) {
        return tutorImage;
      }
    }
    final nestedData = source['data'];
    if (nestedData is Map<String, dynamic>) {
      return _extractTeacherImageUrl(nestedData);
    }
    return '';
  }

  String? _firstNonEmptyString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Map<_StudentPaymentMethod, String> _extractTeacherQrMethods(
    Map<String, dynamic> source,
  ) {
    final containers = <Map<String, dynamic>>[source];
    final nestedKeys = [
      'payment',
      'paymentMethods',
      'payout',
      'qrCodes',
      'tutor'
    ];
    for (final key in nestedKeys) {
      final nested = source[key];
      if (nested is Map<String, dynamic>) {
        containers.add(nested);
      }
    }
    final tutor = source['tutor'];
    if (tutor is Map<String, dynamic>) {
      final nested = tutor['paymentMethods'];
      if (nested is Map<String, dynamic>) {
        containers.add(nested);
      }
    }
    final urls = <_StudentPaymentMethod, String>{};
    for (final method in _StudentPaymentMethod.values) {
      final url = _firstMethodUrl(containers, method.keyCandidates);
      if (url != null && url.isNotEmpty) {
        urls[method] = _assetUrl(url);
      }
    }
    return urls;
  }

  String? _firstMethodUrl(
    List<Map<String, dynamic>> containers,
    List<String> keys,
  ) {
    for (final container in containers) {
      for (final key in keys) {
        final value = container[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
        if (value is Map<String, dynamic>) {
          final nested = value['url']?.toString() ??
              value['imageUrl']?.toString() ??
              value['qrUrl']?.toString() ??
              value['path']?.toString();
          if (nested != null && nested.trim().isNotEmpty) {
            return nested.trim();
          }
        }
      }
    }
    return null;
  }

  Future<void> _pickPaymentScreenshot() async {
    final selected = await Navigator.of(context).push<SelectedFile>(
      MaterialPageRoute(
        builder: (_) => const FilePickerScreen(
          title: 'Upload payment screenshot',
          allowPdf: false,
          allowAny: false,
          allowImages: true,
          allowCamera: true,
        ),
      ),
    );
    if (selected == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _paymentScreenshot = selected;
    });
  }

  Future<void> _submitPaymentForApproval(Course course) async {
    if (_isApprovalPending) {
      return;
    }
    if (_paymentScreenshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Upload screenshot image first, then submit.')),
      );
      return;
    }

    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit payment.')),
      );
      Navigator.of(context).pushNamed(AppRoutes.login);
      return;
    }

    setState(() {
      _isSubmittingPayment = true;
    });

    try {
      final screenshot = _paymentScreenshot!;
      final upload = await _buildMultipartFile(screenshot, 'screenshot');
      final submitResponse = await _apiClient.postMultipart(
        '/api/v1/payments/submit',
        token: token,
        fields: {
          'courseId': course.id,
          'paymentMethod': _selectedPaymentMethod.apiValue,
          'amount': course.price.toString(),
        },
        files: [upload],
      );
      await _createTeacherRequestWithScreenshot(
        token: token,
        course: course,
        screenshot: screenshot,
        paymentResponse: submitResponse,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _isApprovalPending = true;
        _paymentStatusMessage = 'Payment submitted. Approval pending.';
      });
      _startAccessPolling(course);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment submitted. Approval pending.')),
      );
    } on HttpException catch (err) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to submit payment for approval.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingPayment = false;
        });
      }
    }
  }

  bool _isRouteUnavailable(HttpException err) {
    if (err.statusCode == 404 ||
        err.statusCode == 405 ||
        err.statusCode == 501) {
      return true;
    }
    if (err.statusCode == 400) {
      final lower = err.message.toLowerCase();
      return lower.contains('route') ||
          lower.contains('endpoint') ||
          lower.contains('not found') ||
          lower.contains('not available');
    }
    return false;
  }

  Future<void> _createTeacherRequestWithScreenshot({
    required String token,
    required Course course,
    required SelectedFile screenshot,
    required Map<String, dynamic> paymentResponse,
  }) async {
    final body = <String, String>{
      'courseId': course.id,
      'course': course.id,
      if ((course.tutorId ?? '').isNotEmpty) 'tutor': course.tutorId!,
      'message': 'Payment screenshot submitted for course access.',
      'paymentMethod': _selectedPaymentMethod.apiValue,
      'amount': course.price.toString(),
    };
    final multipartPaths = <String>[
      '/api/v1/teacher-requests',
      '/api/v1/teacher-requests/payment',
      '/api/v1/teacher-requests/submit',
    ];
    final fileFields = <String>['screenshot', 'paymentScreenshot', 'proof'];
    for (final path in multipartPaths) {
      for (final field in fileFields) {
        try {
          await _apiClient.postMultipart(
            path,
            token: token,
            fields: body,
            files: [await _buildMultipartFile(screenshot, field)],
          );
          return;
        } on HttpException catch (err) {
          if (_isRouteUnavailable(err)) {
            continue;
          }
          rethrow;
        }
      }
    }

    final responseData = paymentResponse['data'];
    final responseMap = responseData is Map
        ? Map<String, dynamic>.from(responseData)
        : <String, dynamic>{};
    final screenshotUrl = (responseMap['screenshotUrl'] ??
            responseMap['paymentScreenshotUrl'] ??
            responseMap['proofImageUrl'] ??
            responseMap['imageUrl'])
        ?.toString();
    try {
      await _apiClient.postJson(
        '/api/v1/teacher-requests',
        token: token,
        body: <String, dynamic>{
          'course': course.id,
          'courseId': course.id,
          if ((course.tutorId ?? '').isNotEmpty) 'tutor': course.tutorId,
          'message': 'Payment screenshot submitted for course access.',
          'paymentMethod': _selectedPaymentMethod.apiValue,
          'amount': course.price,
          if (screenshotUrl != null && screenshotUrl.trim().isNotEmpty)
            'screenshotUrl': screenshotUrl.trim(),
        },
      );
    } on HttpException catch (err) {
      if (!_isRouteUnavailable(err)) {
        rethrow;
      }
    }
  }

  Future<http.MultipartFile> _buildMultipartFile(
    SelectedFile file,
    String fieldName,
  ) async {
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return http.MultipartFile.fromBytes(
        fieldName,
        file.bytes!,
        filename: file.name,
      );
    }
    if (file.path != null && file.path!.isNotEmpty) {
      return http.MultipartFile.fromPath(fieldName, file.path!);
    }
    throw Exception('File data unavailable');
  }

  Future<void> _loadFavoriteStatus(String courseId) async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty || courseId.isEmpty) {
      return;
    }
    final paths = <String>[
      '/api/v1/users/me/favorites',
      '/api/users/me/favorites',
      '/api/v1/favorites',
    ];
    for (final path in paths) {
      try {
        final response = await _apiClient.getJson(path, token: token);
        final data = response['data'];
        var found = false;
        if (data is Map<String, dynamic>) {
          final courses = data['courses'];
          if (courses is List) {
            for (final row in courses.whereType<Map<String, dynamic>>()) {
              final id = row['_id']?.toString() ?? row['id']?.toString() ?? '';
              if (id == courseId) {
                found = true;
                break;
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
            if (id == courseId) {
              found = true;
              break;
            }
          }
        }
        if (!mounted) {
          return;
        }
        setState(() {
          _isFavorite = found;
        });
        return;
      } on HttpException catch (err) {
        if (err.statusCode == 404 || err.statusCode == 405) {
          continue;
        }
        return;
      } catch (_) {
        return;
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final course = _course;
    final token = HiveService.authToken;
    if (course == null || token == null || token.isEmpty || _isFavoriteBusy) {
      return;
    }
    final next = !_isFavorite;
    setState(() {
      _isFavoriteBusy = true;
      _isFavorite = next;
    });
    try {
      if (next) {
        final paths = <String>[
          '/api/v1/users/me/favorites/courses/${course.id}',
          '/api/users/me/favorites/courses/${course.id}',
          '/api/v1/favorites',
        ];
        var ok = false;
        for (final path in paths) {
          try {
            if (path.endsWith('/favorites')) {
              await _apiClient.postJson(
                path,
                token: token,
                body: {'courseId': course.id},
              );
            } else {
              await _apiClient.postJson(path, token: token, body: const {});
            }
            ok = true;
            break;
          } on HttpException catch (err) {
            if (err.statusCode == 404 || err.statusCode == 405) {
              continue;
            }
            rethrow;
          }
        }
        if (!ok) {
          throw Exception('Unable to add favorite');
        }
      } else {
        final paths = <String>[
          '/api/v1/users/me/favorites/courses/${course.id}',
          '/api/users/me/favorites/courses/${course.id}',
          '/api/v1/favorites/${course.id}',
        ];
        var ok = false;
        for (final path in paths) {
          try {
            await _apiClient.deleteJson(path, token: token);
            ok = true;
            break;
          } on HttpException catch (err) {
            if (err.statusCode == 404 || err.statusCode == 405) {
              continue;
            }
            rethrow;
          }
        }
        if (!ok) {
          throw Exception('Unable to remove favorite');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFavoriteBusy = false;
        });
      }
    }
  }

  Future<void> _markLessonCompleted(Lesson lesson) async {
    final course = _course;
    if (course == null || lesson.id.isEmpty) {
      return;
    }
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      return;
    }
    final paths = <Future<void> Function()>[
      () => _apiClient.postJson(
            '/api/v1/enrollments/${course.id}/lessons/${lesson.id}/complete',
            token: token,
            body: const {},
          ),
      () => _apiClient.postJson(
            '/api/v1/lessons/${lesson.id}/complete',
            token: token,
            body: {'courseId': course.id},
          ),
      () => _apiClient.patchJson(
            '/api/v1/enrollments/${course.id}/progress',
            token: token,
            body: {'lessonId': lesson.id, 'status': 'completed'},
          ),
    ];
    for (final call in paths) {
      try {
        await call();
        return;
      } catch (_) {}
    }
  }

  void _openFirstLesson(Course course) {
    if (_lessons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No lessons available yet.')),
      );
      return;
    }
    final sorted = [..._lessons]..sort((a, b) => a.order.compareTo(b.order));
    Navigator.of(context).pushNamed(
      AppRoutes.coursePlayer,
      arguments: {
        'course': course,
        'lesson': sorted.first,
      },
    );
  }

  String _assetUrl(String? path) {
    if (path == null || path.isEmpty) {
      return '';
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final base = socketBaseUrl();
    if (path.startsWith('/')) {
      return '$base$path';
    }
    return '$base/$path';
  }

  List<_CourseMaterialItem> _extractLessonMaterials(
    Map<String, dynamic> lesson,
  ) {
    final items = <_CourseMaterialItem>[];
    final lessonTitle = lesson['title']?.toString() ?? 'Lesson';

    void addMaterial(
      String? rawUrl, {
      String? type,
      String? title,
    }) {
      final url = _assetUrl(rawUrl);
      if (url.isEmpty) {
        return;
      }
      items.add(
        _CourseMaterialItem(
          title:
              (title?.trim().isNotEmpty == true) ? title!.trim() : lessonTitle,
          url: url,
          type: _materialType(type, url),
          lessonTitle: lessonTitle,
        ),
      );
    }

    addMaterial(lesson['imageUrl']?.toString(), type: 'image');
    addMaterial(lesson['pdfUrl']?.toString(), type: 'pdf');
    addMaterial(lesson['videoUrl']?.toString(), type: 'video');
    addMaterial(lesson['fileUrl']?.toString(),
        type: lesson['fileType']?.toString());
    addMaterial(lesson['resourceUrl']?.toString(), type: 'resource');

    final materials = lesson['materials'];
    if (materials is List) {
      for (final row in materials.whereType<Map<String, dynamic>>()) {
        addMaterial(
          row['url']?.toString() ??
              row['fileUrl']?.toString() ??
              row['path']?.toString(),
          type: row['type']?.toString() ?? row['fileType']?.toString(),
          title: row['title']?.toString() ?? row['name']?.toString(),
        );
      }
    }

    final dedup = <String, _CourseMaterialItem>{};
    for (final item in items) {
      dedup[item.url] = item;
    }
    return dedup.values.toList();
  }

  _CourseMaterialType _materialType(String? type, String url) {
    final t = (type ?? '').toLowerCase();
    final u = url.toLowerCase();
    if (t.contains('pdf') || u.endsWith('.pdf')) {
      return _CourseMaterialType.pdf;
    }
    if (t.contains('image') ||
        t.contains('jpg') ||
        t.contains('jpeg') ||
        t.contains('png') ||
        u.endsWith('.jpg') ||
        u.endsWith('.jpeg') ||
        u.endsWith('.png') ||
        u.endsWith('.webp') ||
        u.endsWith('.gif')) {
      return _CourseMaterialType.image;
    }
    if (t.contains('video') ||
        u.endsWith('.mp4') ||
        u.endsWith('.mov') ||
        u.endsWith('.mkv') ||
        u.endsWith('.webm')) {
      return _CourseMaterialType.video;
    }
    return _CourseMaterialType.other;
  }

  Future<void> _openCourseMaterial(_CourseMaterialItem item) async {
    if (item.type == _CourseMaterialType.image) {
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: InteractiveViewer(
            child: Image.network(
              item.url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 120,
                child: Center(child: Icon(Icons.broken_image)),
              ),
            ),
          ),
        ),
      );
      return;
    }

    if (kIsWeb) {
      final uri = Uri.tryParse(item.url);
      if (uri == null) {
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    final localPath = await _downloadCourseMaterialToLocal(item);
    if (localPath == null || localPath.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open file.')),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    if (item.type == _CourseMaterialType.pdf) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfViewerPage(
            path: localPath,
            title: item.title.trim().isEmpty ? 'PDF' : item.title,
          ),
        ),
      );
      return;
    }

    if (item.type == _CourseMaterialType.video) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoViewerPage(
            path: localPath,
            title: item.title.trim().isEmpty ? 'Video' : item.title,
          ),
        ),
      );
      return;
    }

    await _openUrl('file://$localPath');
  }

  Future<void> _openUrl(String url) async {
    final safeUrl = url.replaceFirst('file://', '');
    final uri = url.startsWith('file://') ? Uri.file(safeUrl) : Uri.tryParse(url);
    if (uri == null) {
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open file.')),
      );
    }
  }

  String _fileNameForMaterial(_CourseMaterialItem item) {
    final raw = item.url.trim();
    final uri = Uri.tryParse(raw);
    final last = (uri?.pathSegments.isNotEmpty == true)
        ? uri!.pathSegments.last
        : raw.split('/').last.split('\\').last;
    final base = last.trim().isEmpty ? item.title.trim() : last.trim();
    if (base.contains('.')) {
      return base;
    }
    final ext = switch (item.type) {
      _CourseMaterialType.pdf => 'pdf',
      _CourseMaterialType.video => 'mp4',
      _CourseMaterialType.image => 'jpg',
      _CourseMaterialType.other => 'bin',
    };
    return '$base.$ext';
  }

  Future<String?> _downloadCourseMaterialToLocal(_CourseMaterialItem item) async {
    final uri = Uri.tryParse(item.url);
    if (uri == null) {
      return null;
    }
    final token = HiveService.authToken;
    return downloadToLocalFile(
      uri: uri,
      fileName: _fileNameForMaterial(item),
      headers: (token != null && token.isNotEmpty)
          ? {'Authorization': 'Bearer $token'}
          : null,
    );
  }

  Widget _buildMaterialTypeSection(String title, _CourseMaterialType type) {
    final items = _materials.where((item) => item.type == type).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22 / 1.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontFamily: 'OpenSans',
            ),
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text(
              'No items yet.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'OpenSans',
              ),
            ),
          ...items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    item.type == _CourseMaterialType.pdf
                        ? Icons.picture_as_pdf_outlined
                        : item.type == _CourseMaterialType.video
                            ? Icons.videocam_outlined
                            : item.type == _CourseMaterialType.image
                                ? Icons.image_outlined
                                : Icons.insert_drive_file_outlined,
                    size: 22,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.lessonTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openCourseMaterial(item),
                    child: const Text('Open'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await _openCourseMaterial(item);
                    },
                    child: const Text('Download'),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _openLessonMaterials(Lesson lesson) async {
    final imageUrl = _assetUrl(lesson.imageUrl);
    final pdfUrl = _assetUrl(lesson.pdfUrl);
    if (imageUrl.isEmpty && pdfUrl.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'OpenSans',
                ),
              ),
              const SizedBox(height: 12),
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              if (pdfUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _openCourseMaterial(
                      _CourseMaterialItem(
                        title: '${lesson.title} PDF',
                        url: pdfUrl,
                        type: _CourseMaterialType.pdf,
                        lessonTitle: lesson.title,
                      ),
                    );
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Open PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.buttonText,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentMethodChip(_StudentPaymentMethod method) {
    final isSelected = method == _selectedPaymentMethod;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.divider),
        ),
        child: Text(
          method.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.buttonText : AppColors.textSecondary,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherQrPreview() {
    final qrUrl = _teacherQrByMethod[_selectedPaymentMethod];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 190,
      height: 165,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _selectedPaymentMethod.previewColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: qrUrl == null
                ? Icon(
                    _selectedPaymentMethod.fallbackIcon,
                    size: 34,
                    color: _selectedPaymentMethod.previewColor,
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      qrUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        _selectedPaymentMethod.fallbackIcon,
                        size: 34,
                        color: _selectedPaymentMethod.previewColor,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 10),
          Text(
            _selectedPaymentMethod.label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'OpenSans',
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Teacher QR',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontFamily: 'OpenSans',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final course = _course;
    if (course == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              const Text(
                'Course not found',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  fontFamily: 'OpenSans',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Header Section
                Container(
                  height: 300,
                  decoration: const BoxDecoration(
                    color: AppColors.headerPink,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: _courseCoverUrl != null &&
                                _courseCoverUrl!.trim().isNotEmpty
                            ? Image.network(
                                _courseCoverUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: AppColors.headerPink,
                                ),
                              )
                            : Container(color: AppColors.headerPink),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.08),
                                Colors.black.withOpacity(0.22),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 50,
                        left: 24,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      if (course.isBestseller)
                        Positioned(
                          top: 100,
                          left: 24,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bestsellerYellow,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Text(
                              'BESTSELLER',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontFamily: 'OpenSans',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 40,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 24,
                        bottom: 60,
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: _teacherImageUrl != null &&
                                    _teacherImageUrl!.trim().isNotEmpty
                                ? Image.network(
                                    _teacherImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.person,
                                      size: 54,
                                      color: AppColors.primary.withOpacity(0.4),
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 54,
                                    color: AppColors.primary.withOpacity(0.4),
                                  ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 24,
                        child: Row(
                          children: [
                            Icon(
                              Icons.send,
                              size: 16,
                              color: AppColors.textPrimary.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 40,
                              height: 2,
                              decoration: BoxDecoration(
                                color: AppColors.textPrimary.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Content Section - Positioned to overlap
                Positioned(
                  top: 280,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  course.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'OpenSans',
                                  ),
                                ),
                              ),
                              Text(
                                _formatPrice(course.price),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontFamily: 'OpenSans',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            course.id == '1'
                                ? '6h 14min · ${course.lessonCount} Lessons'
                                : '${course.durationHours}h ${((course.durationHours * 60) % 60).toString().padLeft(2, '0')}min · ${course.lessonCount} Lessons',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'About this course',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            course.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontFamily: 'OpenSans',
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.expand_more,
                                color: AppColors.textLight,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (_isLockedForStudent) ...[
                            const Text(
                              'Course not available yet. Request tutor approval first.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.redAccent,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Payment required',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_paymentStatusMessage != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        _paymentStatusMessage!,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                          fontFamily: 'OpenSans',
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Center(
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      alignment: WrapAlignment.center,
                                      children: _StudentPaymentMethod.values
                                          .map(_buildPaymentMethodChip)
                                          .toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Center(child: _buildTeacherQrPreview()),
                                  const SizedBox(height: 10),
                                  if (_teacherQrByMethod[
                                          _selectedPaymentMethod] ==
                                      null)
                                    const Text(
                                      'QR not uploaded for selected method. Ask teacher to upload this method.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange,
                                        fontFamily: 'OpenSans',
                                      ),
                                    ),
                                  const SizedBox(height: 10),
                                  GestureDetector(
                                    onTap: _isApprovalPending
                                        ? null
                                        : _pickPaymentScreenshot,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.background,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: AppColors.divider),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.upload_file_outlined,
                                            size: 18,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _paymentScreenshot?.name ??
                                                  'Upload Screenshot',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textSecondary,
                                                fontFamily: 'OpenSans',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_paymentScreenshot?.bytes != null &&
                                      _paymentScreenshot!
                                          .bytes!.isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        _paymentScreenshot!.bytes!,
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  PrimaryButton(
                                    text: _isApprovalPending
                                        ? 'Approval Pending'
                                        : (_isSubmittingPayment
                                            ? 'Submitting...'
                                            : 'Submit Payment for Approval'),
                                    onPressed: (_isApprovalPending ||
                                            _isSubmittingPayment)
                                        ? null
                                        : () =>
                                            _submitPaymentForApproval(course),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (!_isLockedForStudent) ...[
                            const Text(
                              'Lesson materials by type',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildMaterialTypeSection(
                              'VIDEOS',
                              _CourseMaterialType.video,
                            ),
                            _buildMaterialTypeSection(
                              'PDFS',
                              _CourseMaterialType.pdf,
                            ),
                            _buildMaterialTypeSection(
                              'IMAGES',
                              _CourseMaterialType.image,
                            ),
                            _buildMaterialTypeSection(
                              'OTHER RESOURCES',
                              _CourseMaterialType.other,
                            ),
                            const SizedBox(height: 8),
                          ],
                          if (_isLockedForStudent)
                            const SizedBox(height: 0)
                          else if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_errorMessage != null)
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
                            )
                          else if (_lessons.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: Text(
                                'No lessons yet.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'OpenSans',
                                ),
                              ),
                            )
                          else
                            ..._lessons.map((lesson) {
                              return LessonListItem(
                                lesson: lesson,
                                onTap: () {
                                  if (_isLockedForStudent) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Teacher approval pending. Course will open after approval.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _lessons = _lessons.map((item) {
                                      if (item.id != lesson.id) {
                                        return item;
                                      }
                                      return Lesson(
                                        id: item.id,
                                        title: item.title,
                                        durationMinutes: item.durationMinutes,
                                        isCompleted: true,
                                        isLocked: item.isLocked,
                                        order: item.order,
                                        imageUrl: item.imageUrl,
                                        pdfUrl: item.pdfUrl,
                                      );
                                    }).toList();
                                  });
                                  _markLessonCompleted(lesson);
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.coursePlayer,
                                    arguments: {
                                      'course': course,
                                      'lesson': lesson,
                                    },
                                  );
                                },
                                onMaterialsTap: () =>
                                    _openLessonMaterials(lesson),
                              );
                            }),
                          const SizedBox(height: 100), // Space for bottom bar
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _isFavoriteBusy ? null : _toggleFavorite,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _isFavorite
                          ? const Color(0xFFFFEEF2)
                          : AppColors.favoriteOrangeLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _isFavorite
                            ? const Color(0xFFFF5478)
                            : AppColors.favoriteOrange,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite
                          ? const Color(0xFFFF5478)
                          : AppColors.favoriteOrange,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _isLockedForStudent
                      ? PrimaryButton(
                          text: _isApprovalPending
                              ? 'Approval Pending'
                              : (_isRequesting
                                  ? 'Sending...'
                                  : 'Message Tutor for Access'),
                          onPressed: (_isApprovalPending ||
                                  _isRequesting ||
                                  _isCheckingAccess)
                              ? null
                              : () => _sendTeacherRequest(course),
                        )
                      : PrimaryButton(
                          text: HiveService.currentUserRole?.toLowerCase() ==
                                  'student'
                              ? 'Open Course'
                              : 'Buy Now',
                          onPressed: HiveService.currentUserRole
                                      ?.toLowerCase() ==
                                  'student'
                              ? () => _openFirstLesson(course)
                              : () {
                                  final token = HiveService.authToken;
                                  if (token == null || token.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Please log in to purchase.'),
                                      ),
                                    );
                                    Navigator.of(context)
                                        .pushNamed(AppRoutes.login);
                                    return;
                                  }
                                  if (course.id.isEmpty || course.price <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Course information is missing.'),
                                      ),
                                    );
                                    return;
                                  }
                                  Navigator.of(context).pushNamed(
                                    AppRoutes.paymentMethod,
                                    arguments: {
                                      'returnRoute': AppRoutes.courseDetail,
                                      'returnArgs': course,
                                      'courseId': course.id,
                                      'amount': course.price,
                                    },
                                  );
                                },
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
