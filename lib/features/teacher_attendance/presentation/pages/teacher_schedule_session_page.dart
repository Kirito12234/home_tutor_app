import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/widgets/primary_button.dart';

class TeacherScheduleSessionPage extends StatefulWidget {
  const TeacherScheduleSessionPage({super.key});

  @override
  State<TeacherScheduleSessionPage> createState() => _TeacherScheduleSessionPageState();
}

class _TeacherScheduleSessionPageState extends State<TeacherScheduleSessionPage> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _durationController = TextEditingController(text: '60');
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  final List<_SessionItem> _sessions = <_SessionItem>[];
  final List<_CourseOption> _courses = <_CourseOption>[];
  final List<_StudentOption> _students = <_StudentOption>[];

  String? _selectedCourseId;
  String? _selectedStudentId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? warning;
    try {
      await _loadCourses();
      await _loadStudents();
      await _loadSessions();
    } on HttpException catch (err) {
      warning = _isRouteUnavailable(err)
          ? 'Some session data endpoints are unavailable. You can still create sessions.'
          : err.message;
    } catch (_) {
      warning = 'Unable to load some session data.';
    } finally {
      if (mounted) {
        setState(() {
          final selectedCourseExists = _selectedCourseId != null &&
              _courses.any((course) => course.id == _selectedCourseId);
          _selectedCourseId = selectedCourseExists
              ? _selectedCourseId
              : (_courses.isNotEmpty ? _courses.first.id : null);

          final selectedStudentExists = _selectedStudentId != null &&
              _students.any((student) => student.id == _selectedStudentId);
          _selectedStudentId = selectedStudentExists
              ? _selectedStudentId
              : (_students.isNotEmpty ? _students.first.id : null);
          _errorMessage = warning;
          _isLoading = false;
        });
      }
    }
  }

  List<T> _dedupeById<T>(List<T> items, String Function(T) idOf) {
    final seen = <String>{};
    final unique = <T>[];
    for (final item in items) {
      final id = idOf(item).trim();
      if (id.isEmpty || seen.contains(id)) {
        continue;
      }
      seen.add(id);
      unique.add(item);
    }
    return unique;
  }

  Future<void> _loadCourses() async {
    final currentName = HiveService.currentUserName;
    final query = (currentName != null && currentName.trim().isNotEmpty)
        ? '?instructor=${Uri.encodeComponent(currentName)}'
        : '';

    final response = await _apiClient.getJson(
      '/api/v1/courses$query',
      token: HiveService.authToken,
    );
    final data = response['data'];
    if (data is! List) {
      return;
    }

    final mapped = data
        .whereType<Map<String, dynamic>>()
        .map(_CourseOption.fromJson)
        .where((course) => course.id.isNotEmpty)
        .toList();

    _courses
      ..clear()
      ..addAll(_dedupeById<_CourseOption>(mapped, (course) => course.id));
  }

  Future<void> _loadStudents() async {
    final token = HiveService.authToken;
    final paths = <String>[
      '/api/v1/tutor-students?status=active',
      '/api/v1/teacher-requests?status=accepted',
      '/api/v1/teacher-requests',
    ];

    HttpException? lastError;
    for (final path in paths) {
      try {
        final response = await _apiClient.getJson(path, token: token);
        final data = response['data'];
        if (data is! List) {
          continue;
        }

        final mapped = data
            .whereType<Map<String, dynamic>>()
            .where((row) {
              if (!path.contains('teacher-requests')) {
                return true;
              }
              final status = row['status']?.toString().toLowerCase() ?? '';
              return status == 'accepted' || status == 'active';
            })
            .map(_StudentOption.fromJson)
            .where((student) => student.id.isNotEmpty)
            .toList();
        final unique =
            _dedupeById<_StudentOption>(mapped, (student) => student.id);
        if (unique.isNotEmpty || path.contains('teacher-requests')) {
          _students
            ..clear()
            ..addAll(unique);
          return;
        }
      } on HttpException catch (err) {
        lastError = err;
        if (_isRouteUnavailable(err)) {
          continue;
        }
        rethrow;
      }
    }

    if (lastError != null && !_isRouteUnavailable(lastError)) {
      throw lastError;
    }
    _students.clear();
  }

  Future<void> _loadSessions() async {
    try {
      final response = await _apiClient.getJson(
        '/api/v1/sessions',
        token: HiveService.authToken,
      );
      final data = response['data'];
      if (data is! List) {
        _sessions.clear();
        return;
      }

      final mapped = data
          .whereType<Map<String, dynamic>>()
          .map(_SessionItem.fromJson)
          .toList();
      mapped.sort((a, b) => a.startTime.compareTo(b.startTime));

      _sessions
        ..clear()
        ..addAll(mapped.where((session) => session.status != 'cancelled'));
    } on HttpException catch (err) {
      if (_isRouteUnavailable(err)) {
        _sessions.clear();
        return;
      }
      rethrow;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _selectedDate = picked;
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _selectedTime = picked;
    });
  }

  Future<void> _submitCreateSession() async {
    if (_selectedCourseId == null || _selectedStudentId == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select course, student, date and time.')),
      );
      return;
    }

    final duration = int.tryParse(_durationController.text.trim()) ?? 60;
    final startTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _apiClient.postJson(
        '/api/v1/sessions',
        token: HiveService.authToken,
        body: <String, dynamic>{
          'course': _selectedCourseId,
          'student': _selectedStudentId,
          'startTime': startTime.toUtc().toIso8601String(),
          'durationMinutes': duration,
          'notes': _notesController.text.trim(),
          'status': 'scheduled',
        },
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session created.')),
      );

      _selectedDate = null;
      _selectedTime = null;
      _durationController.text = '60';
      _notesController.clear();

      await _loadSessions();
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
          const SnackBar(content: Text('Unable to create session.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$mm/$dd/${date.year}';
  }

  String _formatSessionTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final minute = local.minute.toString().padLeft(2, '0');
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final mm = local.month.toString().padLeft(2, '0');
    final dd = local.day.toString().padLeft(2, '0');
    return '$mm/$dd/${local.year} $hour:$minute $period';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      default:
        return 'scheduled';
    }
  }

  bool _isRouteUnavailable(HttpException err) {
    if (err.statusCode == 404 || err.statusCode == 405 || err.statusCode == 501) {
      return true;
    }
    final msg = err.message.toLowerCase();
    return msg.contains('route not found') ||
        msg.contains('endpoint') ||
        msg.contains('not available');
  }

  InputDecoration _fieldDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'OpenSans',
        color: AppColors.textSecondary,
        fontSize: 13,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.background,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  Widget _buildSessionItem(_SessionItem session) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.categoryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'OpenSans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatSessionTime(session.startTime),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _statusLabel(session.status),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'OpenSans',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseDropdownValue = _selectedCourseId != null &&
            _courses.any((course) => course.id == _selectedCourseId)
        ? _selectedCourseId
        : null;
    final studentDropdownValue = _selectedStudentId != null &&
            _students.any((student) => student.id == _selectedStudentId)
        ? _selectedStudentId
        : null;

    final selectedCourse = _courses
        .where((item) => item.id == courseDropdownValue)
        .cast<_CourseOption?>()
        .firstWhere(
          (item) => item != null,
          orElse: () => null,
        );

    return Scaffold(
      backgroundColor: AppColors.teacherBackground,
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
          'Schedule Session',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.teacherSurfaceAlt,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upcoming sessions',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.redAccent,
                          fontFamily: 'OpenSans',
                        ),
                      ),
                    ),
                  if (!_isLoading && _errorMessage == null && _sessions.isEmpty)
                    const Text(
                      'No upcoming sessions.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ..._sessions.take(5).map(_buildSessionItem),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.teacherSurfaceAlt,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create session',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: courseDropdownValue,
                          decoration: _fieldDecoration('Select course'),
                          items: _courses
                              .map(
                                (course) => DropdownMenuItem<String>(
                                  value: course.id,
                                  child: Text(
                                    course.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _courses.isEmpty
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedCourseId = value;
                                  });
                                },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: studentDropdownValue,
                          decoration: _fieldDecoration('Select student'),
                          items: _students
                              .map(
                                (student) => DropdownMenuItem<String>(
                                  value: student.id,
                                  child: Text(
                                    student.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: _students.isEmpty
                              ? null
                              : (value) {
                                  setState(() {
                                    _selectedStudentId = value;
                                  });
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          onTap: _pickDate,
                          decoration: _fieldDecoration(
                            _selectedDate == null ? 'mm/dd/yyyy' : _formatDate(_selectedDate!),
                            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          onTap: _pickTime,
                          decoration: _fieldDecoration(
                            _selectedTime == null
                                ? '--:-- --'
                                : _selectedTime!.format(context),
                            suffixIcon: const Icon(Icons.access_time, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration('60'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _notesController,
                          decoration: _fieldDecoration('Notes (optional)'),
                        ),
                      ),
                    ],
                  ),
                  if (selectedCourse != null && selectedCourse.features.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Course features: ${selectedCourse.features}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  PrimaryButton(
                    text: 'Create session',
                    height: 48,
                    borderRadius: 16,
                    isLoading: _isSubmitting,
                    onPressed: (_courses.isEmpty || _students.isEmpty || _isSubmitting)
                        ? null
                        : _submitCreateSession,
                  ),
                  if (_courses.isEmpty || _students.isEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Please make sure you have at least one course and one student.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionItem {
  const _SessionItem({
    required this.id,
    required this.title,
    required this.startTime,
    required this.status,
  });

  final String id;
  final String title;
  final DateTime startTime;
  final String status;

  static _SessionItem fromJson(Map<String, dynamic> json) {
    final course = json['course'];
    final courseMap = course is Map<String, dynamic> ? course : <String, dynamic>{};
    final student = json['student'];
    final studentMap = student is Map<String, dynamic> ? student : <String, dynamic>{};

    final courseTitle = courseMap['title']?.toString() ?? 'Course';
    final studentName = studentMap['name']?.toString() ?? 'Student';
    final startTime = DateTime.tryParse(json['startTime']?.toString() ?? '') ?? DateTime.now();

    return _SessionItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: '$courseTitle - $studentName',
      startTime: startTime,
      status: json['status']?.toString() ?? 'scheduled',
    );
  }
}

class _CourseOption {
  const _CourseOption({
    required this.id,
    required this.title,
    required this.features,
  });

  final String id;
  final String title;
  final String features;

  static _CourseOption fromJson(Map<String, dynamic> json) {
    final featuresValue = json['features'];
    String features = '';
    if (featuresValue is List) {
      features = featuresValue.map((item) => item.toString()).join(', ');
    } else if (featuresValue is String) {
      features = featuresValue;
    }

    return _CourseOption(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Course',
      features: features,
    );
  }
}

class _StudentOption {
  const _StudentOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  static _StudentOption fromJson(Map<String, dynamic> json) {
    final student = json['student'];
    final studentMap = student is Map<String, dynamic> ? student : <String, dynamic>{};
    final directId = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    final directName = json['name']?.toString() ?? '';
    return _StudentOption(
      id: studentMap['_id']?.toString() ??
          studentMap['id']?.toString() ??
          directId,
      name: studentMap['name']?.toString() ??
          (directName.isNotEmpty ? directName : 'Student'),
    );
  }
}


