import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';

class TeacherManageCurriculumPage extends StatefulWidget {
  const TeacherManageCurriculumPage({Key? key, this.course}) : super(key: key);

  final Map<String, dynamic>? course;

  @override
  State<TeacherManageCurriculumPage> createState() => _TeacherManageCurriculumPageState();
}

class _TeacherManageCurriculumPageState extends State<TeacherManageCurriculumPage> {
  final List<_CurriculumItem> _lessons = [];
  int _lessonCounter = 0;

  @override
  void initState() {
    super.initState();
    _seedLessons();
  }

  void _seedLessons() {
    _lessons
      ..clear()
      ..addAll([
        _CurriculumItem(
          id: _nextId(),
          title: 'Course kickoff',
          schedule: 'Week 1 - Monday',
          duration: '45 min',
          type: 'Lecture',
          isPublished: true,
        ),
        _CurriculumItem(
          id: _nextId(),
          title: 'Foundations and tools',
          schedule: 'Week 1 - Thursday',
          duration: '60 min',
          type: 'Practice',
          isPublished: true,
        ),
        _CurriculumItem(
          id: _nextId(),
          title: 'Checkpoint quiz',
          schedule: 'Week 2 - Monday',
          duration: '30 min',
          type: 'Quiz',
          isPublished: false,
        ),
      ]);
  }

  String _nextId() {
    _lessonCounter += 1;
    return 'lesson-$_lessonCounter';
  }

  Future<void> _addLesson() async {
    final created = await _showLessonEditor();
    if (created == null) {
      return;
    }
    setState(() {
      _lessons.add(created.copyWith(id: _nextId()));
    });
  }

  Future<void> _editLesson(_CurriculumItem lesson) async {
    final updated = await _showLessonEditor(existing: lesson);
    if (updated == null) {
      return;
    }
    setState(() {
      final index = _lessons.indexWhere((item) => item.id == lesson.id);
      if (index != -1) {
        _lessons[index] = updated.copyWith(id: lesson.id, isPublished: lesson.isPublished);
      }
    });
  }

  Future<void> _deleteLesson(_CurriculumItem lesson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove lesson?'),
        content: const Text('This will remove the lesson from the curriculum.'),
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    setState(() {
      _lessons.removeWhere((item) => item.id == lesson.id);
    });
  }

  void _togglePublish(_CurriculumItem lesson) {
    setState(() {
      lesson.isPublished = !lesson.isPublished;
    });
  }

  void _moveLesson(_CurriculumItem lesson, int offset) {
    final index = _lessons.indexWhere((item) => item.id == lesson.id);
    final newIndex = index + offset;
    if (index == -1 || newIndex < 0 || newIndex >= _lessons.length) {
      return;
    }
    setState(() {
      _lessons.removeAt(index);
      _lessons.insert(newIndex, lesson);
    });
  }

  Future<_CurriculumItem?> _showLessonEditor({_CurriculumItem? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final scheduleController = TextEditingController(text: existing?.schedule ?? '');
    final durationController = TextEditingController(text: existing?.duration ?? '');
    var selectedType = existing?.type ?? _lessonTypes.first;
    final formKey = GlobalKey<FormState>();

    return showDialog<_CurriculumItem>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add lesson' : 'Edit lesson'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Lesson title'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter a lesson title.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: scheduleController,
                  decoration: const InputDecoration(labelText: 'Schedule'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: 'Duration'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: _lessonTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    selectedType = value;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) {
                return;
              }
              Navigator.of(context).pop(
                _CurriculumItem(
                  id: existing?.id ?? '',
                  title: titleController.text.trim(),
                  schedule: scheduleController.text.trim().isEmpty
                      ? 'Schedule TBD'
                      : scheduleController.text.trim(),
                  duration: durationController.text.trim().isEmpty
                      ? 'Duration TBD'
                      : durationController.text.trim(),
                  type: selectedType,
                  isPublished: existing?.isPublished ?? false,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teacherPrimary,
              foregroundColor: AppColors.buttonText,
            ),
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.course?['title'] as String? ?? 'Course curriculum';
    final subtitle = widget.course?['subtitle'] as String? ?? 'Curriculum overview';
    final weeks = widget.course?['weeks'] as String? ?? '0 weeks';
    final students = widget.course?['students'] as String? ?? '0 students';

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
            fontFamily: 'Inter',
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
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
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
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoPill(label: weeks),
                    const SizedBox(width: 8),
                    _InfoPill(label: students),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lessons',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              TextButton.icon(
                onPressed: _addLesson,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add lesson'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.teacherPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_lessons.isEmpty)
            const Text(
              'No lessons yet. Add your first session.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ..._lessons.map(
            (lesson) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lesson.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      _StatusChip(isPublished: lesson.isPublished),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${lesson.schedule} · ${lesson.duration} · ${lesson.type}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _moveLesson(lesson, -1),
                        icon: const Icon(Icons.arrow_upward),
                        color: AppColors.textSecondary,
                        tooltip: 'Move up',
                      ),
                      IconButton(
                        onPressed: () => _moveLesson(lesson, 1),
                        icon: const Icon(Icons.arrow_downward),
                        color: AppColors.textSecondary,
                        tooltip: 'Move down',
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _togglePublish(lesson),
                        child: Text(lesson.isPublished ? 'Unpublish' : 'Publish'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _editLesson(lesson),
                        icon: const Icon(Icons.edit_outlined),
                        color: AppColors.teacherPrimary,
                        tooltip: 'Edit lesson',
                      ),
                      IconButton(
                        onPressed: () => _deleteLesson(lesson),
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.redAccent,
                        tooltip: 'Remove lesson',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          PrimaryButton(
            text: 'Save curriculum',
            height: 48,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Curriculum updated.')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.isPublished});

  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    final background = isPublished ? AppColors.teacherChip : AppColors.backgroundLight;
    final label = isPublished ? 'Published' : 'Draft';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class _CurriculumItem {
  final String id;
  final String title;
  final String schedule;
  final String duration;
  final String type;
  bool isPublished;

  _CurriculumItem({
    required this.id,
    required this.title,
    required this.schedule,
    required this.duration,
    required this.type,
    required this.isPublished,
  });

  _CurriculumItem copyWith({
    String? id,
    String? title,
    String? schedule,
    String? duration,
    String? type,
    bool? isPublished,
  }) {
    return _CurriculumItem(
      id: id ?? this.id,
      title: title ?? this.title,
      schedule: schedule ?? this.schedule,
      duration: duration ?? this.duration,
      type: type ?? this.type,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}

const List<String> _lessonTypes = ['Lecture', 'Practice', 'Quiz', 'Project'];
