import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/widgets/file_picker_screen.dart';
import '../../../../core/widgets/primary_button.dart';

class TeacherCreateCoursePage extends StatefulWidget {
  const TeacherCreateCoursePage({Key? key}) : super(key: key);

  @override
  State<TeacherCreateCoursePage> createState() => _TeacherCreateCoursePageState();
}

class _TeacherCreateCoursePageState extends State<TeacherCreateCoursePage> {
  final _formKey = GlobalKey<FormState>();
  final ApiClient _apiClient = ApiClient();
  bool _isSubmitting = false;
  bool _isUploadingMaterials = false;
  String? _errorMessage;
  String? _createdCourseId;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _lessonsController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _featuresController = TextEditingController();
  final _lessonTitleController = TextEditingController();
  final _lessonDurationController = TextEditingController();
  final _lessonOrderController = TextEditingController();

  SelectedFile? _courseImageFile;
  SelectedFile? _lessonImageFile;
  SelectedFile? _lessonPdfFile;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _lessonsController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _featuresController.dispose();
    _lessonTitleController.dispose();
    _lessonDurationController.dispose();
    _lessonOrderController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'Please log in to create a course.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    final lessonCount = int.tryParse(_lessonsController.text.trim()) ?? 0;
    final features = _featuresController.text
        .split(',')
        .map((feature) => feature.trim())
        .where((feature) => feature.isNotEmpty)
        .toList();
    final instructorName =
        HiveService.currentUserName ?? 'Instructor';

    try {
      final response = await _apiClient.postJson(
        '/api/v1/courses',
        token: token,
        body: {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _categoryController.text.trim(),
          'price': price,
          'durationHours': duration,
          'lessonCount': lessonCount,
          'instructorName': instructorName,
          'isNew': true,
          'scheduleDate': _dateController.text.trim(),
          'scheduleTime': _timeController.text.trim(),
          'features': features,
        },
      );
      final data = response['data'];
      String? courseId;
      if (data is Map<String, dynamic>) {
        courseId = data['_id']?.toString() ?? data['id']?.toString();
      }
      if (courseId == null || courseId.isEmpty) {
        throw Exception('Missing course id');
      }
      if (_courseImageFile != null) {
        await _uploadCourseImage(courseId, _courseImageFile!);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _createdCourseId = courseId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course created successfully.')),
      );
    } on HttpException catch (err) {
      setState(() {
        _errorMessage = err.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to create course.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _uploadCourseImage(String courseId, SelectedFile file) async {
    final upload = await _buildMultipartFile(file, 'image');
    await _apiClient.postMultipart(
      '/api/v1/courses/$courseId/image',
      token: HiveService.authToken,
      files: [upload],
    );
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
    if (file.path != null) {
      return http.MultipartFile.fromPath(fieldName, file.path!);
    }
    throw Exception('File data not available.');
  }

  bool _isPdfFile(SelectedFile file) {
    final name = file.name.toLowerCase();
    return name.endsWith('.pdf');
  }

  bool _isImageFile(SelectedFile file) {
    final name = file.name.toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp') ||
        name.endsWith('.gif');
  }

  Future<SelectedFile?> _openPicker(String title) async {
    return Navigator.of(context).push<SelectedFile>(
      MaterialPageRoute(
        builder: (_) => FilePickerScreen(title: title),
      ),
    );
  }

  Future<void> _pickCourseImage() async {
    final selected = await _openPicker('Select a photo');
    if (selected == null) {
      return;
    }
    if (!_isImageFile(selected)) {
      _showSnack('Please select an image file.');
      return;
    }
    setState(() {
      _courseImageFile = selected;
    });
  }

  Future<void> _pickLessonImage() async {
    final selected = await _openPicker('Select a photo');
    if (selected == null) {
      return;
    }
    if (!_isImageFile(selected)) {
      _showSnack('Please select an image file.');
      return;
    }
    setState(() {
      _lessonImageFile = selected;
    });
  }

  Future<void> _pickLessonPdf() async {
    final selected = await _openPicker('Select a PDF');
    if (selected == null) {
      return;
    }
    if (!_isPdfFile(selected)) {
      _showSnack('Please select a PDF file.');
      return;
    }
    setState(() {
      _lessonPdfFile = selected;
    });
  }

  Future<void> _createLessonAndUploadMaterials() async {
    if (_createdCourseId == null) {
      return;
    }
    if (_lessonTitleController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Lesson title is required.';
      });
      return;
    }
    if (_lessonImageFile == null && _lessonPdfFile == null) {
      setState(() {
        _errorMessage = 'Please select an image or PDF.';
      });
      return;
    }

    setState(() {
      _isUploadingMaterials = true;
      _errorMessage = null;
    });

    try {
      final durationMinutes =
          int.tryParse(_lessonDurationController.text.trim()) ?? 0;
      final order = int.tryParse(_lessonOrderController.text.trim()) ?? 0;

      final lessonResponse = await _apiClient.postJson(
        '/api/v1/courses/${_createdCourseId!}/lessons',
        token: HiveService.authToken,
        body: {
          'title': _lessonTitleController.text.trim(),
          'durationMinutes': durationMinutes,
          'order': order,
        },
      );
      final lessonData = lessonResponse['data'];
      final lessonId =
          lessonData is Map ? lessonData['_id']?.toString() : null;
      if (lessonId == null || lessonId.isEmpty) {
        throw Exception('Missing lesson id');
      }

      final files = <http.MultipartFile>[];
      if (_lessonImageFile != null) {
        files.add(await _buildMultipartFile(_lessonImageFile!, 'image'));
      }
      if (_lessonPdfFile != null) {
        files.add(await _buildMultipartFile(_lessonPdfFile!, 'pdf'));
      }

      await _apiClient.postMultipart(
        '/api/v1/courses/${_createdCourseId!}/lessons/$lessonId/materials',
        token: HiveService.authToken,
        files: files,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _lessonTitleController.clear();
        _lessonDurationController.clear();
        _lessonOrderController.clear();
        _lessonImageFile = null;
        _lessonPdfFile = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lesson materials uploaded.')),
      );
    } on HttpException catch (err) {
      setState(() {
        _errorMessage = err.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to upload lesson materials.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingMaterials = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
          'Create Course',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            _buildField(
              label: 'Title',
              controller: _titleController,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Title is required' : null,
            ),
            _buildField(
              label: 'Description',
              controller: _descriptionController,
              maxLines: 4,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Description is required' : null,
            ),
            _buildField(
              label: 'Category',
              controller: _categoryController,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Category is required' : null,
            ),
            _buildField(
              label: 'Price',
              controller: _priceController,
              keyboardType: TextInputType.number,
            ),
            _buildField(
              label: 'Duration (hours)',
              controller: _durationController,
              keyboardType: TextInputType.number,
            ),
            _buildField(
              label: 'Lesson count',
              controller: _lessonsController,
              keyboardType: TextInputType.number,
            ),
            _buildField(
              label: 'Course date (YYYY-MM-DD)',
              controller: _dateController,
            ),
            _buildField(
              label: 'Course time (HH:mm)',
              controller: _timeController,
            ),
            _buildField(
              label: 'Features (comma separated)',
              controller: _featuresController,
            ),
            _buildFilePicker(
              label: 'Course image (optional)',
              fileName: _courseImageFile?.name,
              onPick: _pickCourseImage,
              onClear: _courseImageFile == null
                  ? null
                  : () {
                      setState(() {
                        _courseImageFile = null;
                      });
                    },
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
            PrimaryButton(
              text: _isSubmitting ? 'Creating...' : 'Create course',
              height: 46,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
            ),
            if (_createdCourseId != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Add lesson materials',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 12),
              _buildField(
                label: 'Lesson title',
                controller: _lessonTitleController,
              ),
              _buildField(
                label: 'Lesson duration (minutes)',
                controller: _lessonDurationController,
                keyboardType: TextInputType.number,
              ),
              _buildField(
                label: 'Lesson order',
                controller: _lessonOrderController,
                keyboardType: TextInputType.number,
              ),
              _buildFilePicker(
                label: 'Lesson image (optional)',
                fileName: _lessonImageFile?.name,
                onPick: _pickLessonImage,
                onClear: _lessonImageFile == null
                    ? null
                    : () {
                        setState(() {
                          _lessonImageFile = null;
                        });
                      },
              ),
              _buildFilePicker(
                label: 'Lesson PDF (optional)',
                fileName: _lessonPdfFile?.name,
                onPick: _pickLessonPdf,
                onClear: _lessonPdfFile == null
                    ? null
                    : () {
                        setState(() {
                          _lessonPdfFile = null;
                        });
                      },
              ),
              PrimaryButton(
                text: _isUploadingMaterials
                    ? 'Uploading...'
                    : 'Upload lesson materials',
                height: 46,
                isLoading: _isUploadingMaterials,
                onPressed:
                    _isUploadingMaterials ? null : _createLessonAndUploadMaterials,
              ),
              const SizedBox(height: 12),
              Text(
                'Students will be notified after material upload.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
          ),
          filled: true,
          fillColor: AppColors.backgroundLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFilePicker({
    required String label,
    required String? fileName,
    required VoidCallback onPick,
    VoidCallback? onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                fileName == null ? label : fileName,
                style: TextStyle(
                  fontSize: 13,
                  color: fileName == null
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            TextButton(
              onPressed: onPick,
              child: const Text('Choose'),
            ),
            if (onClear != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.textSecondary,
                onPressed: onClear,
              ),
          ],
        ),
      ),
    );
  }
}
