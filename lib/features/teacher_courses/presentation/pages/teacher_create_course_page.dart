import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/widgets/file_picker_screen.dart';
import '../../../../core/widgets/pdf_viewer_page.dart';
import '../../../../core/widgets/platform_file_image.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/video_viewer_page.dart';

class TeacherCreateCoursePage extends StatefulWidget {
  const TeacherCreateCoursePage({Key? key}) : super(key: key);

  @override
  State<TeacherCreateCoursePage> createState() =>
      _TeacherCreateCoursePageState();
}

class _TeacherCreateCoursePageState extends State<TeacherCreateCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();
  final _title = TextEditingController();
  final _category = TextEditingController();
  final _description = TextEditingController();
  final _features = TextEditingController();
  final _price = TextEditingController();
  final _lessonTitle = TextEditingController();
  final _lessonDescription = TextEditingController();

  final _levels = const ['Beginner', 'Intermediate', 'Advanced'];
  String _level = 'Beginner';
  _LessonType _selectedType = _LessonType.pdf;
  SelectedFile? _courseImage;
  SelectedFile? _coursePdf;
  SelectedFile? _selectedLessonFile;
  final List<_LessonDraft> _lessons = [];
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _category.dispose();
    _description.dispose();
    _features.dispose();
    _price.dispose();
    _lessonTitle.dispose();
    _lessonDescription.dispose();
    for (final item in _lessons) {
      item.dispose();
    }
    super.dispose();
  }

  bool _isPdf(SelectedFile f) => f.name.toLowerCase().endsWith('.pdf');

  bool _isImage(SelectedFile f) {
    final n = f.name.toLowerCase();
    return n.endsWith('.jpg') ||
        n.endsWith('.jpeg') ||
        n.endsWith('.png') ||
        n.endsWith('.webp') ||
        n.endsWith('.gif');
  }

  Future<bool> _isOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return result.any((x) => x != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  Future<SelectedFile?> _pick({
    required String title,
    bool allowImages = true,
    bool allowPdf = true,
    bool allowAny = true,
    bool allowCamera = true,
  }) {
    return Navigator.of(context).push<SelectedFile>(
      MaterialPageRoute(
        builder: (_) => FilePickerScreen(
          title: title,
          allowImages: allowImages,
          allowPdf: allowPdf,
          allowAny: allowAny,
          allowCamera: allowCamera,
        ),
      ),
    );
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _pickCourseImage() async {
    final f = await _pick(
      title: 'Select course image',
      allowImages: true,
      allowPdf: false,
      allowAny: false,
      allowCamera: true,
    );
    if (f == null) return;
    if (!_isImage(f)) return _showSnack('Please choose a valid image file.');
    setState(() => _courseImage = f);
  }

  Future<void> _pickCoursePdf() async {
    final f = await _pick(
      title: 'Select course PDF',
      allowImages: false,
      allowPdf: true,
      allowAny: false,
      allowCamera: false,
    );
    if (f == null) return;
    if (!_isPdf(f)) return _showSnack('Please choose a PDF file.');
    setState(() => _coursePdf = f);
  }

  Future<void> _pickLessonFile() async {
    final f = await _pick(
      title: 'Select lesson file',
      allowImages: _selectedType == _LessonType.image,
      allowPdf: _selectedType == _LessonType.pdf,
      allowAny: _selectedType == _LessonType.video ||
          _selectedType == _LessonType.resource,
      allowCamera: _selectedType == _LessonType.image,
    );
    if (f == null) return;
    if (_selectedType == _LessonType.pdf && !_isPdf(f))
      return _showSnack('Selected file must be PDF.');
    if (_selectedType == _LessonType.image && !_isImage(f))
      return _showSnack('Selected file must be an image.');
    setState(() => _selectedLessonFile = f);
  }

  void _addLessonMaterial() {
    final t = _lessonTitle.text.trim();
    if (t.isEmpty) return _showSnack('Lesson title is required.');
    if (_selectedLessonFile == null)
      return _showSnack('Please select a lesson file.');
    setState(() {
      final item = _LessonDraft()
        ..titleController.text = t
        ..descriptionController.text = _lessonDescription.text.trim()
        ..type = _selectedType
        ..file = _selectedLessonFile;
      _lessons.add(item);
      _lessonTitle.clear();
      _lessonDescription.clear();
      _selectedType = _LessonType.pdf;
      _selectedLessonFile = null;
    });
  }

  Future<http.MultipartFile> _toPart(SelectedFile f, String field) async {
    if (f.bytes != null)
      return http.MultipartFile.fromBytes(field, f.bytes!, filename: f.name);
    if (f.path != null && f.path!.isNotEmpty)
      return http.MultipartFile.fromPath(field, f.path!);
    throw Exception('File data unavailable');
  }

  Future<void> _uploadCoursePdf(String courseId, SelectedFile file) async {
    final first = await _toPart(file, 'pdf');
    var uploaded = false;
    try {
      await _apiClient.postMultipart(
        '/api/v1/courses/$courseId/materials',
        token: HiveService.authToken,
        fields: const {'type': 'pdf', 'title': 'Course PDF'},
        files: [first],
      );
      uploaded = true;
    } on HttpException {
      uploaded = false;
    }
    if (uploaded) {
      return;
    }
    final second = await _toPart(file, 'pdf');
    await _apiClient.postMultipart('/api/v1/courses/$courseId/pdf',
        token: HiveService.authToken, files: [second]);
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

  Future<void> _submitAdminApprovalRequest({
    required String courseId,
    required String token,
  }) async {
    final body = <String, dynamic>{
      'courseId': courseId,
      'status': 'pending',
      'approvalStatus': 'pending',
      'requestedBy': HiveService.currentUserName ?? 'Instructor',
    };
    final paths = <String>[
      '/api/v1/courses/$courseId/submit-for-approval',
      '/api/v1/courses/$courseId/request-approval',
      '/api/v1/courses/$courseId/approval-request',
      '/api/v1/course-approvals',
      '/api/v1/admin/course-approvals',
      '/api/v1/admin/course-requests',
    ];
    for (final path in paths) {
      try {
        await _apiClient.postJson(path, token: token, body: body);
        return;
      } on HttpException catch (err) {
        if (_isRouteUnavailable(err)) {
          continue;
        }
        rethrow;
      }
    }
  }

  Map<String, dynamic> _draftForLocal() {
    final now = DateTime.now();
    return {
      'localId': 'local_${now.microsecondsSinceEpoch}',
      'isLocalOnly': true,
      'pendingSync': true,
      'createdAt': now.toIso8601String(),
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'category': _category.text.trim(),
      'level': _level,
      'features': _features.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      'price': double.tryParse(_price.text.trim()) ?? 0,
      'status': 'Pending Sync',
      'approvalStatus': 'pending',
      'isApproved': false,
      'isPublished': false,
      'imageUrl': _courseImage?.path ?? '',
      'courseImage': _courseImage == null
          ? null
          : {'name': _courseImage!.name, 'path': _courseImage!.path ?? ''},
      'coursePdf': _coursePdf == null
          ? null
          : {'name': _coursePdf!.name, 'path': _coursePdf!.path ?? ''},
      'lessons': _lessons
          .map((l) => {
                'title': l.titleController.text.trim(),
                'description': l.descriptionController.text.trim(),
                'type': l.type.apiValue,
                'file': l.file == null
                    ? null
                    : {'name': l.file!.name, 'path': l.file!.path ?? ''},
              })
          .toList(),
      'lessonCount': _lessons.length,
      'instructorName': HiveService.currentUserName ?? 'Instructor',
    };
  }

  Map<String, dynamic> _resultPayload({String? courseId, bool local = false}) {
    return {
      '_id': courseId ?? '',
      'id': courseId ?? '',
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'category': _category.text.trim(),
      'level': _level,
      'price': double.tryParse(_price.text.trim()) ?? 0,
      'lessonCount': _lessons.length,
      'features': _features.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      'status': local ? 'Pending Sync' : 'Pending Admin',
      'approvalStatus': 'pending',
      'isPublished': false,
      'isApproved': false,
      'imageUrl': _courseImage?.path ?? '',
      'coursePdfPath': _coursePdf?.path ?? '',
      'lessons': _lessons
          .map((l) => {
                'title': l.titleController.text.trim(),
                'description': l.descriptionController.text.trim(),
                'fileType': l.type.apiValue,
                'materials': [
                  {
                    'title': l.titleController.text.trim(),
                    'url': l.file?.path ?? '',
                    'type': l.type.apiValue
                  }
                ],
              })
          .toList(),
      'isLocalOnly': local,
    };
  }

  Future<void> _openCreatedCourseDetail({
    required Map<String, dynamic> payload,
  }) async {
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushReplacementNamed(
      AppRoutes.teacherCourseDetail,
      arguments: payload,
    );
  }

  Future<Map<String, dynamic>> _buildCreatedPayloadFromServer(
    String courseId,
  ) async {
    final fallback = _resultPayload(courseId: courseId, local: false);
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      return fallback;
    }

    final merged = Map<String, dynamic>.from(fallback);
    try {
      final courseResponse = await _apiClient.getJson(
        '/api/v1/courses/$courseId',
        token: token,
      );
      final data = courseResponse['data'];
      if (data is Map<String, dynamic>) {
        merged.addAll(data);
        merged['_id'] = data['_id']?.toString() ?? courseId;
        merged['id'] =
            data['_id']?.toString() ?? data['id']?.toString() ?? courseId;
        final serverImageUrl = (data['imageUrl']?.toString() ?? '').trim();
        final serverImage = (data['image']?.toString() ?? '').trim();
        final fallbackImage = (merged['imageUrl']?.toString() ?? '').trim();
        merged['imageUrl'] = serverImageUrl.isNotEmpty
            ? serverImageUrl
            : (serverImage.isNotEmpty ? serverImage : fallbackImage);

        final serverPdfPath = (data['coursePdfPath']?.toString() ?? '').trim();
        final serverPdfUrl = (data['pdfUrl']?.toString() ?? '').trim();
        final serverPdf = (data['pdf']?.toString() ?? '').trim();
        final fallbackPdf = (merged['coursePdfPath']?.toString() ?? '').trim();
        merged['coursePdfPath'] = serverPdfPath.isNotEmpty
            ? serverPdfPath
            : (serverPdfUrl.isNotEmpty
                ? serverPdfUrl
                : (serverPdf.isNotEmpty ? serverPdf : fallbackPdf));
      }
    } catch (_) {}

    try {
      final lessonsResponse = await _apiClient.getJson(
        '/api/v1/courses/$courseId/lessons',
        token: token,
      );
      final lessonsData = lessonsResponse['data'];
      if (lessonsData is List) {
        merged['lessons'] =
            lessonsData.whereType<Map<String, dynamic>>().toList();
      }
    } catch (_) {}

    return merged;
  }

  Future<void> _saveLocal() async {
    if (_coursePdf?.path == null || _coursePdf!.path!.isEmpty) {
      throw Exception('Course PDF needs a local file path for offline save.');
    }
    for (var i = 0; i < _lessons.length; i++) {
      final p = _lessons[i].file?.path;
      if (p == null || p.isEmpty)
        throw Exception('Lesson ${i + 1} file needs a local path.');
    }
    await HiveService.upsertTeacherOfflineCourseDraft(_draftForLocal());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate())
      return _showSnack('Please complete required fields.');
    if (_coursePdf == null)
      return setState(() => _error = 'Course PDF is required.');
    if (_lessons.isEmpty)
      return _showSnack('Please add at least one lesson material.');

    final token = HiveService.authToken;
    if (token == null || token.isEmpty)
      return setState(() => _error = 'Please log in to create course.');

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      if (!await _isOnline()) {
        await _saveLocal();
        if (!mounted) return;
        _showSnack(
            'No internet. Course saved locally and will sync when online.');
        await _openCreatedCourseDetail(
          payload: _resultPayload(local: true),
        );
        return;
      }

      final response =
          await _apiClient.postJson('/api/v1/courses', token: token, body: {
        'title': _title.text.trim(),
        'category': _category.text.trim(),
        'description': _description.text.trim(),
        'features': _features.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'price': double.tryParse(_price.text.trim()) ?? 0,
        'level': _level,
        'lessonCount': _lessons.length,
        'durationHours': 0,
        'instructorName': HiveService.currentUserName ?? 'Instructor',
        'isNew': true,
        'approvalStatus': 'pending',
        'isApproved': false,
        'isPublished': false,
        'status': 'pending',
        'requestAdminApproval': true,
        'needsAdminApproval': true,
      });

      final data = response['data'];
      final courseId = data is Map<String, dynamic>
          ? (data['_id']?.toString() ?? data['id']?.toString() ?? '')
          : '';
      if (courseId.isEmpty) throw Exception('Missing course id');

      if (_courseImage != null) {
        final img = await _toPart(_courseImage!, 'image');
        await _apiClient.postMultipart('/api/v1/courses/$courseId/image',
            token: token, files: [img]);
      }
      await _uploadCoursePdf(courseId, _coursePdf!);

      for (var i = 0; i < _lessons.length; i++) {
        final l = _lessons[i];
        final create = await _apiClient
            .postJson('/api/v1/courses/$courseId/lessons', token: token, body: {
          'title': l.titleController.text.trim(),
          'description': l.descriptionController.text.trim(),
          'durationMinutes': 0,
          'order': i + 1,
          'fileType': l.type.apiValue,
        });
        final d = create['data'];
        final lessonId =
            d is Map ? (d['_id']?.toString() ?? d['id']?.toString() ?? '') : '';
        if (lessonId.isEmpty)
          throw Exception('Missing lesson id for lesson ${i + 1}');
        final part = await _toPart(l.file!, 'lessonFile');
        await _apiClient.postMultipart(
          '/api/v1/courses/$courseId/lessons/$lessonId/materials',
          token: token,
          fields: {
            'fileType': l.type.apiValue,
            'type': l.type.apiValue,
            if (l.descriptionController.text.trim().isNotEmpty)
              'description': l.descriptionController.text.trim(),
          },
          files: [part],
        );
      }

      await _submitAdminApprovalRequest(courseId: courseId, token: token);

      if (!mounted) return;
      _showSnack(
          'Course submitted for admin approval. Students can see it after approval.');
      final payload = await _buildCreatedPayloadFromServer(courseId);
      await _openCreatedCourseDetail(payload: payload);
    } on HttpException catch (e) {
      if (e.statusCode == 0) {
        try {
          await _saveLocal();
          if (!mounted) return;
          _showSnack(
              'Connection lost. Course saved locally and will sync when online.');
          await _openCreatedCourseDetail(
            payload: _resultPayload(local: true),
          );
          return;
        } catch (localErr) {
          setState(() =>
              _error = localErr.toString().replaceFirst('Exception: ', ''));
          return;
        }
      }
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Unable to create course.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openMaterial(_LessonDraft l) async {
    final p = l.file?.path;
    if (l.type == _LessonType.image && p != null && p.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: InteractiveViewer(
            child: kIsWeb
                ? const Center(child: Icon(Icons.image_outlined))
                : platformFileImage(
                    p,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Center(child: Icon(Icons.broken_image)),
                  ),
          ),
        ),
      );
      return;
    }
    await _downloadMaterial(l);
  }

  Future<void> _downloadMaterial(_LessonDraft l) async {
    final p = l.file?.path;
    if (p == null || p.isEmpty) {
      _showSnack('Local file path not available.');
      return;
    }
    if (!mounted) {
      return;
    }

    final title = l.titleController.text.trim().isNotEmpty
        ? l.titleController.text.trim()
        : (l.file?.name ?? (p.split('/').last.split('\\').last));

    if (!kIsWeb && l.type == _LessonType.pdf) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfViewerPage(path: p, title: title),
        ),
      );
      return;
    }

    if (!kIsWeb && l.type == _LessonType.video) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoViewerPage(path: p, title: title),
        ),
      );
      return;
    }

    final ok =
        await launchUrl(Uri.file(p), mode: LaunchMode.externalApplication);
    if (!ok) {
      _showSnack('Unable to open file.');
    }
  }

  Widget _field({
    required TextEditingController c,
    required String hint,
    int lines = 1,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: c,
      maxLines: lines,
      keyboardType: keyboard,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontFamily: 'OpenSans'),
        filled: true,
        fillColor: AppColors.teacherSurface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.inputBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.primary)),
      ),
    );
  }

  Widget _fileField({
    required String label,
    required SelectedFile? file,
    required VoidCallback onPick,
    VoidCallback? onClear,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.teacherSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          if (file != null && _isImage(file))
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: file.bytes != null
                    ? Image.memory(
                        file.bytes!,
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(Icons.broken_image),
                        ),
                      )
                    : ((file.path ?? '').isNotEmpty && !kIsWeb)
                        ? platformFileImage(
                            file.path!,
                            width: 42,
                            height: 42,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox(
                              width: 42,
                              height: 42,
                              child: Icon(Icons.broken_image),
                            ),
                          )
                        : const SizedBox(
                            width: 42,
                            height: 42,
                            child: Icon(Icons.image_outlined),
                          ),
              ),
            ),
          Expanded(
            child: Text(
              file?.name ?? label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13,
                  color: file == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontFamily: 'OpenSans'),
            ),
          ),
          TextButton(onPressed: onPick, child: const Text('Browse')),
          if (onClear != null)
            IconButton(
                icon: const Icon(Icons.close, size: 18), onPressed: onClear),
        ],
      ),
    );
  }

  Widget _typeSection(String title, _LessonType type) {
    final items =
        _lessons.asMap().entries.where((e) => e.value.type == type).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.teacherSurface,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'OpenSans')),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('No items yet.',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.teacherMuted,
                    fontFamily: 'OpenSans')),
          ...items.map((e) {
            final i = e.key;
            final l = e.value;
            final p = l.file?.path;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  if (type == _LessonType.image && l.file != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: l.file!.bytes != null
                          ? Image.memory(
                              l.file!.bytes!,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                width: 42,
                                height: 42,
                                child: Icon(Icons.broken_image),
                              ),
                            )
                          : (p != null && p.isNotEmpty && !kIsWeb)
                              ? platformFileImage(
                                  p,
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(
                                    width: 42,
                                    height: 42,
                                    child: Icon(Icons.broken_image),
                                  ),
                                )
                              : const SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: Icon(Icons.image_outlined),
                                ),
                    )
                  else
                    Icon(type.icon,
                        size: 22, color: AppColors.teacherPrimaryDark),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.titleController.text.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontFamily: 'OpenSans')),
                        const SizedBox(height: 2),
                        Text(
                          l.descriptionController.text.trim().isEmpty
                              ? (l.file?.name ?? '')
                              : l.descriptionController.text.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.teacherMuted,
                              fontFamily: 'OpenSans'),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                      onPressed: () => _openMaterial(l),
                      child: const Text('Open')),
                  TextButton(
                      onPressed: () => _downloadMaterial(l),
                      child: const Text('Download')),
                  TextButton(
                      onPressed: () =>
                          setState(() => _lessons.removeAt(i).dispose()),
                      child: const Text('Delete',
                          style: TextStyle(color: Colors.redAccent))),
                ],
              ),
            );
          }),
        ],
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
        title: const Text('Create Course',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.teacherPrimaryDark,
                fontFamily: 'OpenSans')),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(children: [
              Expanded(
                  child: _field(
                      c: _title,
                      hint: 'Title',
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null)),
              const SizedBox(width: 10),
              Expanded(child: _field(c: _category, hint: 'Category'))
            ]),
            const SizedBox(height: 10),
            _field(c: _description, hint: 'Description', lines: 4),
            const SizedBox(height: 10),
            _field(c: _features, hint: 'Features (comma separated)'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _field(
                        c: _price,
                        hint: 'Price',
                        keyboard: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _level,
                    items: _levels
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => setState(() => _level = v ?? _level),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.teacherSurface,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.inputBorder)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.primary)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _fileField(
                label: 'Course image (optional)',
                file: _courseImage,
                onPick: _pickCourseImage,
                onClear: _courseImage == null
                    ? null
                    : () => setState(() => _courseImage = null)),
            _fileField(
                label: 'Course PDF (required)',
                file: _coursePdf,
                onPick: _pickCoursePdf,
                onClear: _coursePdf == null
                    ? null
                    : () => setState(() => _coursePdf = null)),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.teacherSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.inputBorder)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add lesson material',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'OpenSans')),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: _field(c: _lessonTitle, hint: 'Lesson title')),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<_LessonType>(
                          initialValue: _selectedType,
                          items: _LessonType.values
                              .map((x) => DropdownMenuItem(
                                  value: x, child: Text(x.label)))
                              .toList(),
                          onChanged: (v) => setState(() {
                            _selectedType = v ?? _selectedType;
                            _selectedLessonFile = null;
                          }),
                          decoration: const InputDecoration(
                              border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _field(
                      c: _lessonDescription,
                      hint: 'Lesson description (optional)',
                      lines: 2),
                  const SizedBox(height: 10),
                  _fileField(
                      label: 'Select lesson file',
                      file: _selectedLessonFile,
                      onPick: _pickLessonFile,
                      onClear: _selectedLessonFile == null
                          ? null
                          : () => setState(() => _selectedLessonFile = null)),
                  SizedBox(
                      height: 40,
                      child: PrimaryButton(
                          text: 'Add lesson material',
                          onPressed: _addLessonMaterial)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('Lesson materials by type',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'OpenSans')),
            const SizedBox(height: 10),
            _typeSection('VIDEOS', _LessonType.video),
            _typeSection('PDFS', _LessonType.pdf),
            _typeSection('IMAGES', _LessonType.image),
            _typeSection('OTHER RESOURCES', _LessonType.resource),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_error!,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.redAccent,
                        fontFamily: 'OpenSans')),
              ),
            PrimaryButton(
                text: _isSubmitting ? 'Creating...' : 'Create course',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit),
          ],
        ),
      ),
    );
  }
}

enum _LessonType {
  pdf('PDF', 'pdf', Icons.picture_as_pdf_outlined),
  video('Video', 'video', Icons.videocam_outlined),
  image('Image', 'image', Icons.image_outlined),
  resource('Resource', 'resource', Icons.insert_drive_file_outlined);

  const _LessonType(this.label, this.apiValue, this.icon);
  final String label;
  final String apiValue;
  final IconData icon;
}

class _LessonDraft {
  _LessonDraft()
      : titleController = TextEditingController(),
        descriptionController = TextEditingController();
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  _LessonType type = _LessonType.pdf;
  SelectedFile? file;

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
  }
}
