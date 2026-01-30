import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/widgets/primary_button.dart';

class TeacherScheduleSessionPage extends StatefulWidget {
  const TeacherScheduleSessionPage({Key? key}) : super(key: key);

  @override
  State<TeacherScheduleSessionPage> createState() => _TeacherScheduleSessionPageState();
}

class _TeacherScheduleSessionPageState extends State<TeacherScheduleSessionPage> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  bool _isLoadingPros = false;
  String? _errorMessage;
  String? _prosErrorMessage;
  final List<_SessionItem> _sessions = [];
  final List<_CourseOption> _courses = [];
  final List<_StudentOption> _students = [];
  final List<_ProItem> _professionals = [];

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
        _loadCourses(),
        _loadStudents(),
        _loadSessions(),
        _loadProfessionals(),
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
          _errorMessage = 'Unable to load sessions.';
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
        .map((course) => _CourseOption(
              id: course['_id']?.toString() ?? course['id']?.toString() ?? '',
              title: course['title']?.toString() ?? 'Course',
            ))
        .where((course) => course.id.isNotEmpty)
        .toList();
    _courses
      ..clear()
      ..addAll(mapped);
  }

  Future<void> _loadStudents() async {
    final response = await _apiClient.getJson(
      '/api/v1/tutor-students?status=active',
      token: HiveService.authToken,
    );
    final data = response['data'];
    if (data is! List) {
      return;
    }
    final mapped = data
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final student = item['student'];
          final studentMap = student is Map<String, dynamic> ? student : <String, dynamic>{};
          return _StudentOption(
            id: studentMap['_id']?.toString() ?? studentMap['id']?.toString() ?? '',
            name: studentMap['name']?.toString() ?? 'Student',
          );
        })
        .where((student) => student.id.isNotEmpty)
        .toList();
    _students
      ..clear()
      ..addAll(mapped);
  }

  Future<void> _loadSessions() async {
    final response = await _apiClient.getJson(
      '/api/v1/sessions',
      token: HiveService.authToken,
    );
    final data = response['data'];
    if (data is! List) {
      return;
    }
    final mapped = data.whereType<Map<String, dynamic>>().map(_SessionItem.fromJson).toList();
    _sessions
      ..clear()
      ..addAll(mapped);
  }

  Future<void> _loadProfessionals() async {
    setState(() {
      _isLoadingPros = true;
      _prosErrorMessage = null;
    });

    try {
      final response = await _apiClient.getJson('/api/v1/professionals');
      final data = response['data'];
      if (data is List) {
        final mapped = data
            .whereType<Map<String, dynamic>>()
            .map(_ProItem.fromJson)
            .toList();
        _professionals
          ..clear()
          ..addAll(mapped);
      } else {
        _prosErrorMessage = 'Unexpected response format.';
      }
    } on HttpException catch (err) {
      _prosErrorMessage = err.message;
    } catch (_) {
      _prosErrorMessage = 'Unable to load professionals.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPros = false;
        });
      }
    }
  }

  Future<void> _openCreateSessionSheet() async {
    if (_courses.isEmpty || _students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a course and a student before scheduling.')),
      );
      return;
    }

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String? selectedCourseId = _courses.first.id;
        String? selectedStudentId = _students.first.id;
        DateTime? selectedDate;
        TimeOfDay? selectedTime;
        final durationController = TextEditingController(text: '60');
        final notesController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create session',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCourseId,
                    decoration: _fieldDecoration('Course'),
                    items: _courses
                        .map(
                          (course) => DropdownMenuItem(
                            value: course.id,
                            child: Text(course.title),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setModalState(() => selectedCourseId = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStudentId,
                    decoration: _fieldDecoration('Student'),
                    items: _students
                        .map(
                          (student) => DropdownMenuItem(
                            value: student.id,
                            child: Text(student.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setModalState(() => selectedStudentId = value),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 1)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setModalState(() => selectedDate = picked);
                            }
                          },
                          child: Text(
                            selectedDate == null
                                ? 'Pick date'
                                : _formatDate(selectedDate!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );
                            if (picked != null) {
                              setModalState(() => selectedTime = picked);
                            }
                          },
                          child: Text(
                            selectedTime == null
                                ? 'Pick time'
                                : selectedTime!.format(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration('Duration (minutes)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: _fieldDecoration('Notes (optional)'),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Create session',
                    height: 46,
                    onPressed: () async {
                      if (selectedCourseId == null ||
                          selectedStudentId == null ||
                          selectedDate == null ||
                          selectedTime == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all fields.')),
                        );
                        return;
                      }
                      final startTime = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                      );
                      final durationMinutes =
                          int.tryParse(durationController.text.trim()) ?? 60;
                      final success = await _createSession(
                        courseId: selectedCourseId!,
                        studentId: selectedStudentId!,
                        startTime: startTime,
                        durationMinutes: durationMinutes,
                        notes: notesController.text.trim(),
                      );
                      if (success && context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (created == true) {
      await _loadSessions();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<bool> _createSession({
    required String courseId,
    required String studentId,
    required DateTime startTime,
    required int durationMinutes,
    required String notes,
  }) async {
    try {
      await _apiClient.postJson(
        '/api/v1/sessions',
        token: HiveService.authToken,
        body: {
          'course': courseId,
          'student': studentId,
          'startTime': startTime.toUtc().toIso8601String(),
          'durationMinutes': durationMinutes,
          'notes': notes,
          'status': 'scheduled',
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session created.')),
        );
      }
      return true;
    } on HttpException catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.message)),
        );
      }
      return false;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to create session.')),
        );
      }
      return false;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Scheduled';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatSessionTime(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = dateTime.toLocal();
    final month = months[local.month - 1];
    final day = local.day;
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $hour:$minute $period';
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
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
          'Schedule Session',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          PrimaryButton(
            text: 'Create new session',
            height: 46,
            onPressed: _openCreateSessionSheet,
          ),
          const SizedBox(height: 16),
          const Text(
            'Upcoming sessions',
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
          if (!_isLoading && _errorMessage == null && _sessions.isEmpty)
            const Text(
              'No sessions scheduled yet.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ..._sessions.map(
            (session) => Container(
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
                      color: AppColors.categoryBlue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.event, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatSessionTime(session.startTime),
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
                      _statusLabel(session.status),
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
          const SizedBox(height: 20),
          const Text(
            'Professionals',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingPros)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_prosErrorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _prosErrorMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.redAccent,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          if (!_isLoadingPros &&
              _prosErrorMessage == null &&
              _professionals.isEmpty)
            const Text(
              'No professionals found.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ..._professionals.take(3).map(
                (pro) => Container(
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
                          color: AppColors.categoryBlue,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.person, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pro.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${pro.role} · ${pro.location}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.teacherProfessionals,
                          );
                        },
                        child: const Text('View'),
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

class _SessionItem {
  final String id;
  final String title;
  final DateTime startTime;
  final String status;

  const _SessionItem({
    required this.id,
    required this.title,
    required this.startTime,
    required this.status,
  });

  static _SessionItem fromJson(Map<String, dynamic> json) {
    final course = json['course'];
    final courseMap = course is Map<String, dynamic> ? course : <String, dynamic>{};
    final student = json['student'];
    final studentMap = student is Map<String, dynamic> ? student : <String, dynamic>{};
    final courseTitle = courseMap['title']?.toString() ?? 'Course';
    final studentName = studentMap['name']?.toString() ?? 'Student';
    final startTime = DateTime.tryParse(json['startTime']?.toString() ?? '') ??
        DateTime.now();
    return _SessionItem(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: '$courseTitle · $studentName',
      startTime: startTime,
      status: json['status']?.toString() ?? 'scheduled',
    );
  }
}

class _CourseOption {
  final String id;
  final String title;

  const _CourseOption({
    required this.id,
    required this.title,
  });
}

class _StudentOption {
  final String id;
  final String name;

  const _StudentOption({
    required this.id,
    required this.name,
  });
}

class _ProItem {
  final String name;
  final String role;
  final String location;

  const _ProItem({
    required this.name,
    required this.role,
    required this.location,
  });

  static _ProItem fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final userMap = user is Map<String, dynamic> ? user : <String, dynamic>{};
    final subjects = json['subjects'];
    final subjectNames = subjects is List
        ? subjects
            .whereType<Map<String, dynamic>>()
            .map((item) => item['title']?.toString())
            .whereType<String>()
            .toList()
        : <String>[];
    final role = subjectNames.isNotEmpty ? subjectNames.join(', ') : 'Tutor';
    return _ProItem(
      name: userMap['name']?.toString() ?? 'Professional',
      role: role,
      location: json['location']?.toString() ?? 'Remote',
    );
  }
}

