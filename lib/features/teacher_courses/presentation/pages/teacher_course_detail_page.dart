import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/utils/file_download.dart';
import '../../../../core/utils/material_file_utils.dart' as material_utils;
import '../../../../core/widgets/file_picker_screen.dart';
import '../../../../core/widgets/pdf_viewer_page.dart';
import '../../../../core/widgets/platform_file_image.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/video_viewer_page.dart';

class TeacherCourseDetailPage extends StatefulWidget {
  const TeacherCourseDetailPage({super.key, this.course});

  final Map<String, dynamic>? course;

  @override
  State<TeacherCourseDetailPage> createState() =>
      _TeacherCourseDetailPageState();
}

class _TeacherCourseDetailPageState extends State<TeacherCourseDetailPage> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _lessonTitleController = TextEditingController();
  final TextEditingController _lessonDescriptionController =
      TextEditingController();
  bool _isLoading = false;
  bool _isSubmittingLesson = false;
  String? _errorMessage;
  Map<String, dynamic> _course = <String, dynamic>{};
  List<_LessonItem> _lessons = [];
  List<_MaterialItem> _materials = [];
  _MaterialType _selectedUploadType = _MaterialType.pdf;
  SelectedFile? _selectedLessonFile;

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();
    _course =
        Map<String, dynamic>.from(widget.course ?? const <String, dynamic>{});
    _loadCourseDetails();
  }

  @override
  void dispose() {
    _lessonTitleController.dispose();
    _lessonDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCourseDetails() async {
    final courseId = _courseId;
    if (courseId.isEmpty) {
      _extractFromLocalCourse();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = HiveService.authToken;
      try {
        final courseResponse = await _apiClient.getJson(
          '/api/v1/courses/$courseId',
          token: token,
        );
        final data = courseResponse['data'];
        if (data is Map<String, dynamic>) {
          final beforeImageUrl = _course['imageUrl']?.toString() ?? '';
          final beforeImage = _course['image']?.toString() ?? '';
          final beforePdfPath = _course['coursePdfPath']?.toString() ?? '';
          final beforePdfUrl = _course['pdfUrl']?.toString() ?? '';
          final beforePdf = _course['pdf']?.toString() ?? '';
          _course = {
            ..._course,
            ...data,
          };
          final afterImageUrl = _course['imageUrl']?.toString() ?? '';
          final afterImage = _course['image']?.toString() ?? '';
          if (afterImageUrl.trim().isEmpty && afterImage.trim().isEmpty) {
            if (beforeImageUrl.trim().isNotEmpty) {
              _course['imageUrl'] = beforeImageUrl;
            } else if (beforeImage.trim().isNotEmpty) {
              _course['image'] = beforeImage;
            }
          }

          final afterPdfPath = _course['coursePdfPath']?.toString() ?? '';
          final afterPdfUrl = _course['pdfUrl']?.toString() ?? '';
          final afterPdf = _course['pdf']?.toString() ?? '';
          if (afterPdfPath.trim().isEmpty &&
              afterPdfUrl.trim().isEmpty &&
              afterPdf.trim().isEmpty) {
            if (beforePdfPath.trim().isNotEmpty) {
              _course['coursePdfPath'] = beforePdfPath;
            } else if (beforePdfUrl.trim().isNotEmpty) {
              _course['pdfUrl'] = beforePdfUrl;
            } else if (beforePdf.trim().isNotEmpty) {
              _course['pdf'] = beforePdf;
            }
          }
        }
      } on HttpException {
        // Keep local route arguments if details endpoint is unavailable.
      }

      try {
        final lessonsResponse = await _apiClient.getJson(
          '/api/v1/courses/$courseId/lessons',
          token: token,
        );
        final data = lessonsResponse['data'];
        if (data is List) {
          final lessonMaps = data.whereType<Map<String, dynamic>>().toList();
          _lessons = lessonMaps.map(_LessonItem.fromJson).toList();
          final materials = <_MaterialItem>[];
          for (final lesson in lessonMaps) {
            materials.addAll(_extractMaterials(lesson));
          }
          _materials = _addCourseAssetsMaterial(materials);
        }
      } on HttpException catch (err) {
        if (err.statusCode == 404 || err.statusCode == 405) {
          _lessons = <_LessonItem>[];
          _materials = _addCourseAssetsMaterial(<_MaterialItem>[]);
        } else {
          rethrow;
        }
      }
    } on HttpException catch (err) {
      final hasRouteData =
          (_course['title']?.toString().trim().isNotEmpty == true) ||
              (widget.course?['title']?.toString().trim().isNotEmpty == true);
      if ((err.statusCode == 404 || err.statusCode == 405) && hasRouteData) {
        _errorMessage = null;
      } else {
        _errorMessage = err.message;
      }
    } catch (_) {
      _errorMessage = 'Unable to load course details.';
    } finally {
      _extractFromLocalCourse();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _extractFromLocalCourse() {
    final localLessons = _course['lessons'];
    if (localLessons is List) {
      final lessonMaps = localLessons.whereType<Map<String, dynamic>>().toList();
      if (_lessons.isEmpty) {
        _lessons = lessonMaps.map(_LessonItem.fromJson).toList();
      }
      final localMaterials = <_MaterialItem>[];
      for (final lesson in lessonMaps) {
        localMaterials.addAll(_extractMaterials(lesson));
      }
      final merged = <_MaterialItem>[
        ..._materials,
        ...localMaterials.where(
          (item) => !_materials.any((m) => m.url == item.url),
        ),
      ];
      _materials = _addCourseAssetsMaterial(merged);
    } else {
      _materials = _addCourseAssetsMaterial(_materials);
    }
    _mergeCachedMaterials();
  }

  List<_MaterialItem> _addCourseAssetsMaterial(List<_MaterialItem> items) {
    final updated = List<_MaterialItem>.from(items);
    final imageUrl = _resolveAssetUrl(
      _course['imageUrl']?.toString() ??
          _course['image']?.toString() ??
          widget.course?['imageUrl']?.toString(),
    );
    if (imageUrl.isNotEmpty &&
        !updated.any((item) => item.url == imageUrl)) {
      updated.insert(
        0,
        _MaterialItem(
          title: 'Course cover image',
          url: imageUrl,
          type: _MaterialType.image,
          lessonTitle: 'Course',
          isCourseImage: true,
        ),
      );
    }

    final coursePdfUrl = _resolveAssetUrl(
      _course['coursePdfPath']?.toString() ??
          _course['pdfUrl']?.toString() ??
          _course['pdf']?.toString() ??
          _course['coursePdfUrl']?.toString() ??
          _course['coursePdf']?.toString() ??
          widget.course?['coursePdfPath']?.toString() ??
          widget.course?['pdfUrl']?.toString() ??
          widget.course?['pdf']?.toString(),
    );
    if (coursePdfUrl.isNotEmpty &&
        !updated.any((item) => item.url == coursePdfUrl)) {
      updated.insert(
        imageUrl.isNotEmpty ? 1 : 0,
        _MaterialItem(
          title: 'Course PDF',
          url: coursePdfUrl,
          type: _MaterialType.pdf,
          lessonTitle: 'Course',
        ),
      );
    }

    return updated;
  }

  String get _courseId {
    return _course['_id']?.toString() ??
        _course['id']?.toString() ??
        widget.course?['_id']?.toString() ??
        widget.course?['id']?.toString() ??
        '';
  }

  String get _courseKey {
    final id = _courseId.trim();
    if (id.isNotEmpty) {
      return id;
    }
    final localId = (_course['localId']?.toString() ??
            widget.course?['localId']?.toString() ??
            '')
        .trim();
    if (localId.isNotEmpty) {
      return localId;
    }
    final title =
        (_course['title']?.toString() ?? widget.course?['title']?.toString() ?? '')
            .trim();
    return title;
  }

  String _resolveAssetUrl(String? raw) {
    if (raw == null) {
      return '';
    }
    var value = raw.trim();
    if (value.isEmpty) {
      return '';
    }
    if (_isLocalFilePath(value)) {
      return value;
    }
    value = value.replaceAll('\\', '/');
    if (value.startsWith('/api/v1/uploads/') ||
        value.startsWith('/api/v1/public/') ||
        value.startsWith('/api/v1/static/') ||
        value.startsWith('/api/v1/files/') ||
        value.startsWith('/api/v1/media/')) {
      value = value.substring('/api/v1'.length);
    } else if (value.startsWith('api/v1/uploads/') ||
        value.startsWith('api/v1/public/') ||
        value.startsWith('api/v1/static/') ||
        value.startsWith('api/v1/files/') ||
        value.startsWith('api/v1/media/')) {
      value = value.substring('api/v1'.length);
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final base = socketBaseUrl();
    if (value.startsWith('/')) {
      return '$base$value';
    }
    return '$base/$value';
  }

  bool _isLocalFilePath(String value) {
    return material_utils.isLocalFilePath(value);
  }

  List<String> get _features {
    final raw = _course['features'] ?? widget.course?['features'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (raw is String) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<_MaterialItem> _extractMaterials(Map<String, dynamic> lesson) {
    final items = <_MaterialItem>[];
    final title = lesson['title']?.toString() ?? 'Lesson';
    final lessonId =
        lesson['_id']?.toString() ?? lesson['id']?.toString() ?? '';

    void addFromUrl(
      String? rawUrl, {
      String? rawType,
      String? rawTitle,
      String? fallbackType,
      String? materialId,
    }) {
      final url = _resolveAssetUrl(rawUrl);
      if (url.isEmpty) {
        return;
      }
      items.add(
        _MaterialItem(
          title: rawTitle?.isNotEmpty == true ? rawTitle! : title,
          url: url,
          type: _materialType(rawType: rawType ?? fallbackType, url: url),
          lessonTitle: title,
          lessonId: lessonId,
          materialId: materialId ?? '',
        ),
      );
    }

    final lessonType = lesson['fileType']?.toString();
    final materialList = lesson['materials'];
    if (materialList is List) {
      for (final entry in materialList.whereType<Map<String, dynamic>>()) {
        addFromUrl(
          entry['url']?.toString() ??
              entry['fileUrl']?.toString() ??
              entry['path']?.toString() ??
              entry['lessonFile']?.toString() ??
              entry['mediaUrl']?.toString() ??
              entry['attachmentUrl']?.toString() ??
              entry['file']?.toString(),
          rawType: entry['type']?.toString() ??
              entry['mimeType']?.toString() ??
              entry['fileType']?.toString() ??
              entry['contentType']?.toString(),
          rawTitle: entry['title']?.toString() ?? entry['name']?.toString(),
          fallbackType: lessonType,
          materialId:
              entry['_id']?.toString() ?? entry['id']?.toString() ?? '',
        );
      }
    }

    addFromUrl(
      lesson['fileUrl']?.toString(),
      rawTitle: lesson['fileName']?.toString(),
      fallbackType: lessonType,
    );
    addFromUrl(
      lesson['pdfUrl']?.toString(),
      rawType: 'pdf',
      fallbackType: lessonType,
    );
    addFromUrl(
      lesson['imageUrl']?.toString(),
      rawType: 'image',
      rawTitle: lesson['title']?.toString(),
      fallbackType: lessonType,
    );
    addFromUrl(
      lesson['videoUrl']?.toString(),
      rawType: 'video',
      fallbackType: lessonType,
    );
    addFromUrl(lesson['resourceUrl']?.toString(), fallbackType: lessonType);
    addFromUrl(
      lesson['pdf']?.toString(),
      rawType: 'pdf',
      fallbackType: lessonType,
    );
    addFromUrl(
      lesson['image']?.toString(),
      rawType: 'image',
      fallbackType: lessonType,
    );
    addFromUrl(
      lesson['video']?.toString(),
      rawType: 'video',
      fallbackType: lessonType,
    );
    addFromUrl(lesson['lessonFile']?.toString(), fallbackType: lessonType);
    addFromUrl(lesson['file']?.toString(), fallbackType: lessonType);
    addFromUrl(lesson['mediaUrl']?.toString(), fallbackType: lessonType);

    int rank(_MaterialType type) {
      switch (type) {
        case _MaterialType.image:
          return 4;
        case _MaterialType.video:
          return 3;
        case _MaterialType.pdf:
          return 2;
        case _MaterialType.other:
          return 1;
      }
    }

    final deduped = <String, _MaterialItem>{};
    for (final item in items) {
      final existing = deduped[item.url];
      if (existing == null || rank(item.type) >= rank(existing.type)) {
        deduped[item.url] = item;
      }
    }
    return deduped.values.toList();
  }

  _MaterialType _materialType({String? rawType, required String url}) {
    final type = (rawType ?? '').toLowerCase();
    if (type.contains('pdf')) {
      return _MaterialType.pdf;
    }
    if (type.contains('video')) {
      return _MaterialType.video;
    }
    if (type.contains('image') ||
        type.contains('photo') ||
        type.contains('jpg') ||
        type.contains('jpeg') ||
        type.contains('png') ||
        type.contains('image/')) {
      return _MaterialType.image;
    }
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.endsWith('.pdf')) {
      return _MaterialType.pdf;
    }
    if (lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.mkv') ||
        lowerUrl.endsWith('.webm')) {
      return _MaterialType.video;
    }
    if (lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp')) {
      return _MaterialType.image;
    }
    return _MaterialType.other;
  }

  _MaterialType _materialTypeFromApi(String raw) {
    final lower = raw.trim().toLowerCase();
    for (final type in _MaterialType.values) {
      if (type.apiValue == lower) {
        return type;
      }
    }
    if (lower.contains('pdf')) return _MaterialType.pdf;
    if (lower.contains('video')) return _MaterialType.video;
    if (lower.contains('image')) return _MaterialType.image;
    return _MaterialType.other;
  }

  bool _sameMaterial(_MaterialItem a, _MaterialItem b) {
    if (a.materialId.isNotEmpty &&
        b.materialId.isNotEmpty &&
        a.materialId == b.materialId) {
      return true;
    }
    return a.url == b.url &&
        a.type == b.type &&
        a.lessonId == b.lessonId;
  }

  void _mergeCachedMaterials() {
    final key = _courseKey.trim();
    if (key.isEmpty) {
      return;
    }
    final cached = HiveService.getTeacherCourseMaterials(key);
    if (cached.isEmpty) {
      return;
    }

    final cachedMaterials = cached.map((entry) {
      final map = Map<String, dynamic>.from(entry);
      final url = _resolveAssetUrl(map['url']?.toString());
      final rawType = map['type']?.toString() ?? '';
      return _MaterialItem(
        title: map['title']?.toString() ?? 'Material',
        url: url,
        type: _materialTypeFromApi(rawType),
        lessonTitle: map['lessonTitle']?.toString() ?? 'Lesson',
        lessonId: map['lessonId']?.toString() ?? '',
        materialId: map['materialId']?.toString() ?? '',
      );
    }).toList();

    final merged = <_MaterialItem>[
      ..._materials,
      ...cachedMaterials.where((cachedItem) {
        return !_materials.any((serverItem) => _sameMaterial(serverItem, cachedItem));
      }),
    ];
    _materials = _addCourseAssetsMaterial(merged);
  }

  bool _isPdfFile(SelectedFile file) =>
      (file.extension ?? '').toLowerCase() == 'pdf' ||
      (file.mimeType ?? '').toLowerCase().contains('pdf') ||
      file.name.toLowerCase().endsWith('.pdf');

  bool _isImageFile(SelectedFile file) {
    final ext = (file.extension ?? '').toLowerCase();
    final mime = (file.mimeType ?? '').toLowerCase();
    final lower = file.name.toLowerCase();
    return ext == 'jpg' ||
        ext == 'jpeg' ||
        ext == 'png' ||
        ext == 'webp' ||
        ext == 'gif' ||
        mime.startsWith('image/') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  bool _isVideoFile(SelectedFile file) {
    final ext = (file.extension ?? '').toLowerCase();
    final mime = (file.mimeType ?? '').toLowerCase();
    final lower = file.name.toLowerCase();
    return ext == 'mp4' ||
        ext == 'mov' ||
        ext == 'mkv' ||
        ext == 'webm' ||
        ext == 'avi' ||
        mime.startsWith('video/') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi');
  }

  Future<void> _pickLessonFile() async {
    final selected = await Navigator.of(context).push<SelectedFile>(
      MaterialPageRoute(
        builder: (_) => FilePickerScreen(
          title: 'Select lesson file',
          allowImages: _selectedUploadType == _MaterialType.image,
          allowPdf: _selectedUploadType == _MaterialType.pdf,
          allowAny: _selectedUploadType == _MaterialType.video ||
              _selectedUploadType == _MaterialType.other,
          allowCamera: _selectedUploadType == _MaterialType.image,
        ),
      ),
    );
    if (selected == null || !mounted) {
      return;
    }

    if (_selectedUploadType == _MaterialType.pdf && !_isPdfFile(selected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file.')),
      );
      return;
    }
    if (_selectedUploadType == _MaterialType.image && !_isImageFile(selected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image file.')),
      );
      return;
    }
    if (_selectedUploadType == _MaterialType.video && !_isVideoFile(selected)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video file.')),
      );
      return;
    }

    setState(() {
      _selectedLessonFile = selected;
    });
  }

  Future<http.MultipartFile> _buildMultipartFile(
    SelectedFile file,
    String fieldName,
  ) async {
    if (file.bytes != null) {
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

  Future<void> _addLessonMaterial({bool isRetry = false}) async {
    final courseId = _courseId;
    if (_lessonTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson title is required.')),
      );
      return;
    }
    if (_selectedLessonFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a lesson file.')),
      );
      return;
    }
    if (courseId.isEmpty) {
      await _addLessonMaterialLocally();
      return;
    }

    setState(() {
      _isSubmittingLesson = true;
    });

    try {
      final lessonResponse = await _apiClient.postJson(
        '/api/v1/courses/$courseId/lessons',
        token: HiveService.authToken,
        body: {
          'title': _lessonTitleController.text.trim(),
          'description': _lessonDescriptionController.text.trim(),
          'durationMinutes': 0,
          'order': _lessons.length + 1,
          'fileType': _selectedUploadType.apiValue,
        },
      );
      final lessonData = lessonResponse['data'];
      final lessonId = lessonData is Map<String, dynamic>
          ? (lessonData['_id']?.toString() ??
              lessonData['id']?.toString() ??
              '')
          : '';
      if (lessonId.isEmpty) {
        throw Exception('Lesson creation failed.');
      }

      final upload = await _buildMultipartFile(
        _selectedLessonFile!,
        'lessonFile',
      );
      final uploadResponse = await _apiClient.postMultipart(
        '/api/v1/courses/$courseId/lessons/$lessonId/materials',
        token: HiveService.authToken,
        fields: {
          'fileType': _selectedUploadType.apiValue,
          'type': _selectedUploadType.apiValue,
          if (_lessonDescriptionController.text.trim().isNotEmpty)
            'description': _lessonDescriptionController.text.trim(),
        },
        files: [upload],
      );

      final responseData = uploadResponse['data'];
      Map<String, dynamic>? responseMap;
      if (responseData is Map) {
        responseMap = Map<String, dynamic>.from(responseData);
      }
      responseMap ??= uploadResponse;
      final uploadedUrl = _resolveAssetUrl(
        responseMap['url']?.toString() ??
            responseMap['fileUrl']?.toString() ??
            responseMap['lessonFile']?.toString() ??
            responseMap['imageUrl']?.toString() ??
            responseMap['pdfUrl']?.toString() ??
            responseMap['videoUrl']?.toString() ??
            responseMap['mediaUrl']?.toString() ??
            responseMap['path']?.toString(),
      );
      final materialId =
          responseMap['_id']?.toString() ?? responseMap['id']?.toString() ?? '';
      if (uploadedUrl.isNotEmpty) {
        final newItem = _MaterialItem(
          title: _lessonTitleController.text.trim(),
          url: uploadedUrl,
          type: _selectedUploadType,
          lessonTitle: _lessonTitleController.text.trim(),
          lessonId: lessonId,
          materialId: materialId,
        );
        _materials = _addCourseAssetsMaterial([newItem, ..._materials]);
        await HiveService.upsertTeacherCourseMaterial(
          _courseKey,
          {
            'title': newItem.title,
            'url': newItem.url,
            'type': newItem.type.apiValue,
            'lessonTitle': newItem.lessonTitle,
            'lessonId': newItem.lessonId,
            'materialId': newItem.materialId,
          },
        );
      }

      if (!mounted) {
        return;
      }
      _lessonTitleController.clear();
      _lessonDescriptionController.clear();
      _selectedLessonFile = null;
      await _loadCourseDetails();
      if (!mounted) {
        return;
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson material added successfully.')),
      );
    } on HttpException catch (err) {
      if (err.statusCode == 0) {
        await _addLessonMaterialLocally(
          snack:
              'Connection lost. Lesson material added locally. It will sync when online.',
        );
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to add lesson material.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingLesson = false;
        });
      }
    }
  }

  Future<void> _addLessonMaterialLocally({
    String snack = 'Lesson material added locally.',
  }) async {
    final lessonTitle = _lessonTitleController.text.trim();
    final lessonDescription = _lessonDescriptionController.text.trim();
    final selected = _selectedLessonFile;
    if (selected == null) {
      _showSnack('Please select a lesson file.');
      return;
    }

    final lessonId = 'local_lesson_${DateTime.now().microsecondsSinceEpoch}';
    final materialId =
        'local_material_${DateTime.now().microsecondsSinceEpoch}';
    var url = selected.path?.trim().isNotEmpty == true ? selected.path!.trim() : '';
    if (url.isEmpty && selected.bytes != null && !kIsWeb) {
      final saved = await writeBytesToLocalFile(
        bytes: selected.bytes!,
        fileName: selected.name,
      );
      if (saved != null && saved.isNotEmpty) {
        url = 'file://$saved';
      }
    }

    final newItem = _MaterialItem(
      title: lessonTitle.isEmpty ? selected.name : lessonTitle,
      url: url,
      type: _selectedUploadType,
      lessonTitle: lessonDescription.isNotEmpty
          ? lessonDescription
          : (lessonTitle.isNotEmpty ? lessonTitle : 'Lesson'),
      lessonId: lessonId,
      materialId: materialId,
    );

    if (mounted) {
      setState(() {
      _lessons = [
        ..._lessons,
        _LessonItem(
          title: lessonTitle,
          durationMinutes: 0,
          order: _lessons.length + 1,
        ),
      ];

      _materials = _addCourseAssetsMaterial([
        ..._materials,
        newItem,
      ]);

      _lessonTitleController.clear();
      _lessonDescriptionController.clear();
      _selectedLessonFile = null;
      _isSubmittingLesson = false;
      });
    }

    await HiveService.upsertTeacherCourseMaterial(
      _courseKey,
      {
        'title': newItem.title,
        'url': newItem.url,
        'type': newItem.type.apiValue,
        'lessonTitle': newItem.lessonTitle,
        'lessonId': newItem.lessonId,
        'materialId': newItem.materialId,
      },
    );

    _showSnack(snack);
  }

  Future<void> _openUrl(String url) async {
    final safeUrl = url.replaceFirst('file://', '');
    final uri = _isLocalFilePath(url) ? Uri.file(safeUrl) : Uri.tryParse(url);
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

  Future<_MaterialItem?> _cacheLocalCopy(_MaterialItem item) async {
    if (kIsWeb || _isLocalFilePath(item.url)) {
      return item;
    }
    final uri = Uri.tryParse(item.url);
    if (uri == null) {
      return null;
    }
    final savedPath = await downloadToLocalFile(
      uri: uri,
      fileName: _fileNameFromUrl(item),
      headers: (HiveService.authToken?.isNotEmpty == true)
          ? {'Authorization': 'Bearer ${HiveService.authToken}'}
          : null,
    );
    if (savedPath == null || savedPath.isEmpty) {
      return null;
    }

    final nextItem = _MaterialItem(
      title: item.title,
      url: 'file://$savedPath',
      type: item.type,
      lessonTitle: item.lessonTitle,
      lessonId: item.lessonId,
      materialId: item.materialId,
      isCourseImage: item.isCourseImage,
    );
    if (mounted) {
      setState(() {
        final idx = _materials.indexWhere((m) => _sameMaterial(m, item));
        if (idx >= 0) {
          _materials[idx] = nextItem;
        }
      });
    }
    await HiveService.upsertTeacherCourseMaterial(
      _courseKey,
      {
        'title': nextItem.title,
        'url': nextItem.url,
        'type': nextItem.type.apiValue,
        'lessonTitle': nextItem.lessonTitle,
        'lessonId': nextItem.lessonId,
        'materialId': nextItem.materialId,
      },
    );
    return nextItem;
  }

  Future<void> _openMaterial(_MaterialItem item) async {
    if (item.type == _MaterialType.image) {
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: InteractiveViewer(
            child: _isLocalFilePath(item.url)
                ? (kIsWeb
                    ? const Center(child: Icon(Icons.image_outlined))
                    : platformFileImage(
                        item.url.replaceFirst('file://', ''),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Icon(Icons.broken_image)),
                      ))
                : Image.network(
                    item.url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Center(child: Icon(Icons.broken_image)),
                  ),
          ),
        ),
      );
      return;
    }

    final resolved = await _cacheLocalCopy(item);
    if (resolved == null) {
      _showSnack('Unable to open file.');
      return;
    }
    if (!mounted) {
      return;
    }

    if (resolved.type == _MaterialType.pdf && !kIsWeb) {
      final path = resolved.url.replaceFirst('file://', '');
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfViewerPage(
            path: path,
            title: resolved.title.trim().isEmpty ? 'PDF' : resolved.title,
          ),
        ),
      );
      return;
    }

    if (resolved.type == _MaterialType.video && !kIsWeb) {
      final path = resolved.url.replaceFirst('file://', '');
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoViewerPage(
            path: path,
            title: resolved.title.trim().isEmpty ? 'Video' : resolved.title,
          ),
        ),
      );
      return;
    }

    await _openUrl(resolved.url);
  }

  String _fileNameFromUrl(_MaterialItem item) {
    final ext = switch (item.type) {
      _MaterialType.pdf => 'pdf',
      _MaterialType.image => 'jpg',
      _MaterialType.video => 'mp4',
      _MaterialType.other => 'bin',
    };
    return material_utils.fileNameFromUrl(
      url: item.url,
      title: item.title,
      extension: ext,
    );
  }

  Future<void> _downloadMaterial(_MaterialItem item) async {
    if (kIsWeb || _isLocalFilePath(item.url)) {
      await _openMaterial(item);
      return;
    }
    final resolved = await _cacheLocalCopy(item);
    if (resolved == null) {
      _showSnack('Unable to download file.');
      return;
    }
    await _openMaterial(resolved);
  }

  Future<void> _deleteMaterial(_MaterialItem item) async {
    if (item.isCourseImage) {
      _showSnack('Delete course image from course edit, not lesson materials.');
      return;
    }
    final courseId = _courseId;
    final isLocalOnly = courseId.isEmpty ||
        item.lessonId.isEmpty ||
        item.lessonId.startsWith('local_');
    if (isLocalOnly) {
      setState(() {
        _materials = _materials
            .where(
              (entry) =>
                  !(entry.url == item.url &&
                      entry.type == item.type &&
                      entry.lessonId == item.lessonId),
            )
            .toList();
      });
      await HiveService.removeTeacherCourseMaterial(
        courseKey: _courseKey,
        materialId: item.materialId,
        url: item.url,
        type: item.type.apiValue,
        lessonId: item.lessonId,
      );
      _showSnack('Material deleted.');
      return;
    }

    try {
      final materialId =
          item.materialId.isNotEmpty ? item.materialId : 'current';
      await _apiClient.deleteJson(
        '/api/v1/courses/$courseId/lessons/${item.lessonId}/materials/$materialId',
        token: HiveService.authToken,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _materials = _materials
            .where(
              (entry) => !(entry.url == item.url && entry.type == item.type),
            )
            .toList();
      });
      await HiveService.removeTeacherCourseMaterial(
        courseKey: _courseKey,
        materialId: item.materialId,
        url: item.url,
        type: item.type.apiValue,
        lessonId: item.lessonId,
      );
      _showSnack('Material deleted.');
    } on HttpException catch (err) {
      _showSnack(err.message);
    } catch (_) {
      _showSnack('Unable to delete material.');
    }
  }

  Future<void> _deleteCourse() async {
    final courseId = _courseId;
    if (courseId.isEmpty) {
      _showSnack('Missing course id.');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete course'),
          content: const Text(
            'This will remove the course from backend. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final token = HiveService.authToken;
    final deletePaths = <String>[
      '/api/v1/courses/$courseId',
      '/api/v1/courses/$courseId/delete',
    ];
    HttpException? lastError;
    var deleted = false;

    for (final path in deletePaths) {
      try {
        await _apiClient.deleteJson(path, token: token);
        deleted = true;
        break;
      } on HttpException catch (err) {
        lastError = err;
        if (err.statusCode == 404 || err.statusCode == 405) {
          continue;
        }
        break;
      } catch (_) {
        break;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
    });

    if (deleted) {
      _showSnack('Course deleted.');
      Navigator.of(context).pop(true);
      return;
    }

    _showSnack(lastError?.message ?? 'Unable to delete course.');
  }

  Widget _buildTypeSection(String title, _MaterialType type) {
    final items = _materials.where((item) => item.type == type).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.teacherSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
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
                color: AppColors.teacherMuted,
                fontFamily: 'OpenSans',
              ),
            ),
          ...items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (item.type == _MaterialType.image)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _isLocalFilePath(item.url)
                          ? (kIsWeb
                              ? const SizedBox(
                                  width: 42,
                                  height: 42,
                                  child: Icon(Icons.image_outlined),
                                )
                              : platformFileImage(
                                  item.url.replaceFirst('file://', ''),
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const SizedBox(
                                    width: 42,
                                    height: 42,
                                    child: Icon(Icons.broken_image),
                                  ),
                                ))
                          : Image.network(
                              item.url,
                              width: 42,
                              height: 42,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(
                                width: 42,
                                height: 42,
                                child: Icon(Icons.broken_image),
                              ),
                            ),
                    )
                  else
                    Icon(
                      item.type.icon,
                      size: 22,
                      color: AppColors.teacherPrimaryDark,
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
                            color: AppColors.teacherMuted,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openMaterial(item),
                    child: const Text('Open'),
                  ),
                  TextButton(
                    onPressed: () => _downloadMaterial(item),
                    child: const Text('Download'),
                  ),
                  if (!item.isCourseImage)
                    TextButton(
                      onPressed: () => _deleteMaterial(item),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
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
    final title = _course['title']?.toString() ??
        widget.course?['title']?.toString() ??
        'Course detail';
    final description = _course['description']?.toString() ??
        widget.course?['description']?.toString() ??
        'No description provided.';
    final category = _course['category']?.toString() ??
        widget.course?['level']?.toString() ??
        'General';
    final level = _course['level']?.toString() ??
        widget.course?['difficulty']?.toString() ??
        'Beginner';
    final lessonCount =
        (_course['lessonCount'] as num?)?.toInt() ?? _lessons.length;
    final price = (_course['price'] as num?)?.toDouble() ?? 0;
    final imageUrl = _resolveAssetUrl(
      _course['imageUrl']?.toString() ??
          _course['image']?.toString() ??
          widget.course?['imageUrl']?.toString(),
    );
    final coursePdfUrl = _resolveAssetUrl(
      _course['coursePdfPath']?.toString() ??
          _course['pdfUrl']?.toString() ??
          _course['pdf']?.toString() ??
          _course['coursePdfUrl']?.toString() ??
          _course['coursePdf']?.toString() ??
          widget.course?['coursePdfPath']?.toString() ??
          widget.course?['pdfUrl']?.toString() ??
          widget.course?['pdf']?.toString(),
    );

    return Scaffold(
      backgroundColor: AppColors.teacherBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: AppColors.teacherPrimaryDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.teacherPrimaryDark,
            fontFamily: 'OpenSans',
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Delete course',
            onPressed: _isLoading ? null : _deleteCourse,
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCourseDetails,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(minHeight: 2),
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
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.teacherSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _isLocalFilePath(imageUrl)
                          ? (kIsWeb
                              ? Container(
                                  height: 110,
                                  width: double.infinity,
                                  color: AppColors.teacherChip,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.image_outlined, size: 40),
                                )
                              : platformFileImage(
                                  imageUrl.replaceFirst('file://', ''),
                                  height: 170,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 140,
                                    color: AppColors.teacherChip,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                                ))
                          : Image.network(
                              imageUrl,
                              height: 170,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 140,
                                color: AppColors.teacherChip,
                                alignment: Alignment.center,
                                child: const Icon(Icons.image_not_supported),
                              ),
                              ),
                    )
                  else if (coursePdfUrl.isNotEmpty)
                    InkWell(
                      onTap: () => _openMaterial(
                        _MaterialItem(
                          title: 'Course PDF',
                          url: coursePdfUrl,
                          type: _MaterialType.pdf,
                          lessonTitle: 'Course',
                        ),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 110,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.teacherChip,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.picture_as_pdf_outlined,
                          size: 42,
                          color: AppColors.teacherPrimaryDark,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 110,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.teacherChip,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.play_lesson, size: 40),
                    ),
                  const SizedBox(height: 12),
                  const Text(
                    'Course info',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Category: $category\nLevel: $level\nPrice: ${price.toStringAsFixed(0)}\nLessons: $lessonCount',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.teacherMuted,
                      fontFamily: 'OpenSans',
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.teacherSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description.isEmpty
                        ? 'No description provided.'
                        : description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.teacherMuted,
                      fontFamily: 'OpenSans',
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Features',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_features.isEmpty)
                    const Text(
                      'Not specified.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.teacherMuted,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  if (_features.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _features.map((feature) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.teacherChip,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.teacherPrimaryDark,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.teacherSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lessons',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_lessons.isEmpty)
                    const Text(
                      'No lessons yet.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.teacherMuted,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ..._lessons.map((lesson) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.menu_book, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lesson.title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                    fontFamily: 'OpenSans',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Duration: ${lesson.durationMinutes} min · Order: ${lesson.order}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.teacherMuted,
                                    fontFamily: 'OpenSans',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.teacherSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add lesson material',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _lessonTitleController,
                          decoration: const InputDecoration(
                            hintText: 'Lesson title',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<_MaterialType>(
                          initialValue: _selectedUploadType,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: _MaterialType.values.map((type) {
                            return DropdownMenuItem<_MaterialType>(
                              value: type,
                              child: Text(type.label),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() {
                              _selectedUploadType = value;
                              _selectedLessonFile = null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _lessonDescriptionController,
                    decoration: const InputDecoration(
                      hintText: 'Lesson description (optional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _pickLessonFile,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.upload_file,
                              size: 18, color: AppColors.teacherMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedLessonFile?.name ?? 'Select lesson file',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.teacherMuted,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: PrimaryButton(
                      text: _isSubmittingLesson
                          ? 'Adding...'
                          : 'Add lesson material',
                      isLoading: _isSubmittingLesson,
                      onPressed:
                          _isSubmittingLesson ? null : _addLessonMaterial,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Lesson materials by type',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontFamily: 'OpenSans',
              ),
            ),
            const SizedBox(height: 10),
            _buildTypeSection('VIDEOS', _MaterialType.video),
            _buildTypeSection('PDFS', _MaterialType.pdf),
            _buildTypeSection('IMAGES', _MaterialType.image),
            _buildTypeSection('OTHER RESOURCES', _MaterialType.other),
          ],
        ),
      ),
    );
  }
}

class _LessonItem {
  _LessonItem({
    required this.title,
    required this.durationMinutes,
    required this.order,
  });

  final String title;
  final int durationMinutes;
  final int order;

  factory _LessonItem.fromJson(Map<String, dynamic> json) {
    return _LessonItem(
      title: json['title']?.toString() ?? 'Lesson',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

enum _MaterialType {
  video(Icons.videocam_outlined, 'Video', 'video', 'video'),
  pdf(Icons.picture_as_pdf_outlined, 'PDF', 'pdf', 'pdf'),
  image(Icons.image_outlined, 'Image', 'image', 'image'),
  other(Icons.insert_drive_file_outlined, 'Other Resource', 'resource',
      'resource');

  const _MaterialType(this.icon, this.label, this.apiValue, this.uploadField);
  final IconData icon;
  final String label;
  final String apiValue;
  final String uploadField;
}

class _MaterialItem {
  _MaterialItem({
    required this.title,
    required this.url,
    required this.type,
    required this.lessonTitle,
    this.lessonId = '',
    this.materialId = '',
    this.isCourseImage = false,
  });

  final String title;
  final String url;
  final _MaterialType type;
  final String lessonTitle;
  final String lessonId;
  final String materialId;
  final bool isCourseImage;
}

