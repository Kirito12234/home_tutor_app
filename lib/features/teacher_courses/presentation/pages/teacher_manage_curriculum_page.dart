import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routes/app_routes.dart';
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

class TeacherManageCurriculumPage extends StatefulWidget {
  const TeacherManageCurriculumPage({super.key, this.course});

  final Map<String, dynamic>? course;

  @override
  State<TeacherManageCurriculumPage> createState() =>
      _TeacherManageCurriculumPageState();
}

class _TeacherManageCurriculumPageState
    extends State<TeacherManageCurriculumPage> {
  final ApiClient _apiClient = ApiClient();
  final ScrollController _scrollController = ScrollController();
  final List<_CurriculumItem> _lessons = [];
  final List<_MaterialItem> _materials = [];
  final TextEditingController _materialTitleController = TextEditingController();
  final TextEditingController _materialDescriptionController =
      TextEditingController();
  bool _isLoading = false;
  bool _isSubmittingMaterial = false;
  String? _errorMessage;
  _MaterialType _selectedUploadType = _MaterialType.pdf;
  SelectedFile? _selectedLessonFile;

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    setState(fn);
  }

  String get _courseId =>
      widget.course?['_id']?.toString() ??
      widget.course?['id']?.toString() ??
      '';

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _materialTitleController.dispose();
    _materialDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadLessons() async {
    if (_courseId.isEmpty) {
      _setStateIfMounted(() {
        _errorMessage = 'Missing course id.';
      });
      return;
    }

    _setStateIfMounted(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getJson(
        '/api/v1/courses/$_courseId/lessons',
        token: HiveService.authToken,
      );
      final data = response['data'];
      if (data is List) {
        final lessonMaps = data.whereType<Map<String, dynamic>>().toList();
        final mapped = lessonMaps.map(_CurriculumItem.fromJson).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        final materials = <_MaterialItem>[];
        for (final lesson in lessonMaps) {
          materials.addAll(_extractMaterials(lesson));
        }

        final cached = HiveService.getTeacherCourseMaterials(_courseId);
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

        final mergedMaterials = <_MaterialItem>[
          ...materials,
          ...cachedMaterials.where((cachedItem) {
            return !materials.any((serverItem) => _sameMaterial(serverItem, cachedItem));
          }),
        ];
        _setStateIfMounted(() {
          _lessons
            ..clear()
            ..addAll(mapped);
          _materials
            ..clear()
            ..addAll(mergedMaterials);
        });
      }
    } on HttpException catch (err) {
      _setStateIfMounted(() {
        _errorMessage = err.message;
      });
    } catch (_) {
      _setStateIfMounted(() {
        _errorMessage = 'Unable to load curriculum.';
      });
    } finally {
      _setStateIfMounted(() {
        _isLoading = false;
      });
    }
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

  _MaterialType _materialType({String? rawType, required String url}) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp')) {
      return _MaterialType.image;
    }
    if (lowerUrl.endsWith('.mp4') ||
        lowerUrl.endsWith('.mov') ||
        lowerUrl.endsWith('.mkv') ||
        lowerUrl.endsWith('.webm') ||
        lowerUrl.endsWith('.avi')) {
      return _MaterialType.video;
    }
    if (lowerUrl.endsWith('.pdf')) {
      return _MaterialType.pdf;
    }

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

  List<_MaterialItem> _extractMaterials(Map<String, dynamic> lesson) {
    final items = <_MaterialItem>[];
    final lessonTitle = lesson['title']?.toString() ?? 'Lesson';
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
          title: rawTitle?.isNotEmpty == true ? rawTitle! : lessonTitle,
          url: url,
          type: _materialType(rawType: rawType ?? fallbackType, url: url),
          lessonTitle: lessonTitle,
          lessonId: lessonId,
          materialId: materialId ?? '',
        ),
      );
    }

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
          fallbackType: lesson['fileType']?.toString(),
          materialId:
              entry['_id']?.toString() ?? entry['id']?.toString() ?? '',
        );
      }
    }

    final lessonType = lesson['fileType']?.toString();
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
    addFromUrl(
      lesson['lessonFile']?.toString(),
      fallbackType: lessonType,
    );
    addFromUrl(
      lesson['file']?.toString(),
      fallbackType: lessonType,
    );
    addFromUrl(
      lesson['mediaUrl']?.toString(),
      fallbackType: lessonType,
    );

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

  bool _isPdfFile(SelectedFile file) {
    final ext = (file.extension ?? '').toLowerCase();
    final mime = (file.mimeType ?? '').toLowerCase();
    final lower = file.name.toLowerCase();
    return ext == 'pdf' || mime.contains('pdf') || lower.endsWith('.pdf');
  }

  bool _isImageFile(SelectedFile file) {
    final ext = (file.extension ?? '').toLowerCase();
    final mime = (file.mimeType ?? '').toLowerCase();
    const imageExt = {'jpg', 'jpeg', 'png', 'webp', 'gif'};
    final lower = file.name.toLowerCase();
    return imageExt.contains(ext) ||
        mime.startsWith('image/') ||
        imageExt.any((item) => lower.endsWith('.$item'));
  }

  bool _isVideoFile(SelectedFile file) {
    final ext = (file.extension ?? '').toLowerCase();
    final mime = (file.mimeType ?? '').toLowerCase();
    const videoExt = {'mp4', 'mov', 'mkv', 'webm', 'avi'};
    final lower = file.name.toLowerCase();
    return videoExt.contains(ext) ||
        mime.startsWith('video/') ||
        videoExt.any((item) => lower.endsWith('.$item'));
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
      _showSnack('Please select a PDF file.');
      return;
    }
    if (_selectedUploadType == _MaterialType.image && !_isImageFile(selected)) {
      _showSnack('Please select an image file.');
      return;
    }
    if (_selectedUploadType == _MaterialType.video && !_isVideoFile(selected)) {
      _showSnack('Please select a video file.');
      return;
    }
    _setStateIfMounted(() {
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

  Future<void> _addLessonMaterial() async {
    if (_courseId.isEmpty) {
      _showSnack('Missing course id.');
      return;
    }
    if (_materialTitleController.text.trim().isEmpty) {
      _showSnack('Lesson title is required.');
      return;
    }
    if (_selectedLessonFile == null) {
      _showSnack('Please select a lesson file.');
      return;
    }

    _setStateIfMounted(() {
      _isSubmittingMaterial = true;
    });

    try {
      final selectedFile = _selectedLessonFile!;
      final selectedType = _selectedUploadType;
      final selectedTitle = _materialTitleController.text.trim();
      final selectedDescription = _materialDescriptionController.text.trim();

      final lessonResponse = await _apiClient.postJson(
        '/api/v1/courses/$_courseId/lessons',
        token: HiveService.authToken,
        body: {
          'title': selectedTitle,
          'description': selectedDescription,
          'durationMinutes': 0,
          'order': _lessons.length + 1,
          'fileType': selectedType.apiValue,
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

      final upload = await _buildMultipartFile(selectedFile, 'lessonFile');
      final uploadResponse = await _apiClient.postMultipart(
        '/api/v1/courses/$_courseId/lessons/$lessonId/materials',
        token: HiveService.authToken,
        fields: {
          'fileType': selectedType.apiValue,
          'type': selectedType.apiValue,
          if (selectedDescription.isNotEmpty) 'description': selectedDescription,
        },
        files: [upload],
      );

      // Show recently uploaded item immediately in the correct section.
      final responseData = uploadResponse['data'];
      String uploadedUrl = '';
      String materialId = '';
      Map<String, dynamic>? responseMap;
      if (responseData is Map) {
        responseMap = Map<String, dynamic>.from(responseData);
      }
      responseMap ??= uploadResponse;

      uploadedUrl = _resolveAssetUrl(
        responseMap['url']?.toString() ??
            responseMap['fileUrl']?.toString() ??
            responseMap['lessonFile']?.toString() ??
            responseMap['imageUrl']?.toString() ??
            responseMap['pdfUrl']?.toString() ??
            responseMap['videoUrl']?.toString() ??
            responseMap['mediaUrl']?.toString() ??
            responseMap['path']?.toString(),
      );
      materialId =
          responseMap['_id']?.toString() ?? responseMap['id']?.toString() ?? '';

      if (uploadedUrl.isNotEmpty) {
        final newItem = _MaterialItem(
          title: selectedTitle,
          url: uploadedUrl,
          type: selectedType,
          lessonTitle: selectedTitle,
          lessonId: lessonId,
          materialId: materialId,
        );
        _setStateIfMounted(() {
          _materials.insert(0, newItem);
        });
        await HiveService.upsertTeacherCourseMaterial(
          _courseId,
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

      _materialTitleController.clear();
      _materialDescriptionController.clear();
      _setStateIfMounted(() {
        _selectedLessonFile = null;
      });
      await _loadLessons();
      _scrollToMaterials();
      _showSnack('Lesson material added successfully.');
    } on HttpException catch (err) {
      _showSnack(err.message);
    } catch (_) {
      _showSnack('Unable to add lesson material.');
    } finally {
      _setStateIfMounted(() {
        _isSubmittingMaterial = false;
      });
    }
  }

  void _scrollToMaterials() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openUrl(String url) async {
    final safeUrl = url.replaceFirst('file://', '');
    final uri = _isLocalFilePath(url) ? Uri.file(safeUrl) : Uri.tryParse(url);
    if (uri == null) {
      _showSnack('Invalid file url.');
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      _showSnack('Unable to open file.');
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
    );
    _setStateIfMounted(() {
      final idx = _materials.indexWhere((m) => _sameMaterial(m, item));
      if (idx >= 0) {
        _materials[idx] = nextItem;
      }
    });
    await HiveService.upsertTeacherCourseMaterial(
      _courseId,
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
      if (_isLocalFilePath(item.url)) {
        if (kIsWeb) {
          await _openUrl(item.url);
          return;
        }
        await showDialog<void>(
          context: context,
          builder: (_) => Dialog(
            child: InteractiveViewer(
              child: platformFileImage(
                item.url.replaceFirst('file://', ''),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Center(child: Icon(Icons.broken_image)),
              ),
            ),
          ),
        );
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: InteractiveViewer(
            child: Image.network(
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
    if (_courseId.isEmpty || item.lessonId.isEmpty) {
      _setStateIfMounted(() {
        _materials.removeWhere((entry) => _sameMaterial(entry, item));
      });
      await HiveService.removeTeacherCourseMaterial(
        courseKey: _courseId,
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
        '/api/v1/courses/$_courseId/lessons/${item.lessonId}/materials/$materialId',
        token: HiveService.authToken,
      );
      _setStateIfMounted(() {
        _materials.removeWhere(
          (entry) => entry.url == item.url && entry.type == item.type,
        );
      });
      await HiveService.removeTeacherCourseMaterial(
        courseKey: _courseId,
        materialId: item.materialId,
        url: item.url,
        type: item.type.apiValue,
        lessonId: item.lessonId,
      );
      _showSnack('Material deleted.');
    } on HttpException catch (err) {
      if (item.materialId.isEmpty) {
        _setStateIfMounted(() {
          _materials.removeWhere((entry) => _sameMaterial(entry, item));
        });
        await HiveService.removeTeacherCourseMaterial(
          courseKey: _courseId,
          materialId: item.materialId,
          url: item.url,
          type: item.type.apiValue,
          lessonId: item.lessonId,
        );
        _showSnack('Material removed locally.');
        return;
      }
      _showSnack(err.message);
    } catch (_) {
      _showSnack('Unable to delete material.');
    }
  }

  Widget _buildTypeSection(String title, _MaterialType type) {
    final items = _materials.where((item) => item.type == type).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
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

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.course?['title']?.toString() ?? 'Course curriculum';
    final subtitle =
        widget.course?['description']?.toString() ?? 'Curriculum overview';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Manage Curriculum',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'OpenSans',
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.teacherHome,
              (route) => false,
            ),
            icon: const Icon(Icons.dashboard_customize_outlined),
            color: AppColors.textSecondary,
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          if (_isLoading)
            const LinearProgressIndicator(minHeight: 2),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'OpenSans',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
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
                        controller: _materialTitleController,
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
                          _setStateIfMounted(() {
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
                  controller: _materialDescriptionController,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.upload_file,
                          size: 18,
                          color: AppColors.teacherMuted,
                        ),
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
                    text: _isSubmittingMaterial
                        ? 'Adding...'
                        : 'Add lesson material',
                    isLoading: _isSubmittingMaterial,
                    onPressed:
                        _isSubmittingMaterial ? null : _addLessonMaterial,
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
          const SizedBox(height: 8),
          PrimaryButton(
            text: 'Refresh curriculum',
            onPressed: (_isLoading || _isSubmittingMaterial) ? null : _loadLessons,
          ),
        ],
      ),
    );
  }
}

class _CurriculumItem {
  const _CurriculumItem({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.order,
  });

  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final int order;

  factory _CurriculumItem.fromJson(Map<String, dynamic> json) {
    return _CurriculumItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Lesson',
      description: json['description']?.toString() ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

enum _MaterialType {
  video(Icons.videocam_outlined, 'Video', 'video'),
  pdf(Icons.picture_as_pdf_outlined, 'PDF', 'pdf'),
  image(Icons.image_outlined, 'Image', 'image'),
  other(Icons.insert_drive_file_outlined, 'Other Resource', 'resource');

  const _MaterialType(this.icon, this.label, this.apiValue);
  final IconData icon;
  final String label;
  final String apiValue;
}

class _MaterialItem {
  _MaterialItem({
    required this.title,
    required this.url,
    required this.type,
    required this.lessonTitle,
    this.lessonId = '',
    this.materialId = '',
  });

  final String title;
  final String url;
  final _MaterialType type;
  final String lessonTitle;
  final String lessonId;
  final String materialId;
}

