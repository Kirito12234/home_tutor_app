import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/learning_plan_courses.dart';
import '../../../../core/widgets/primary_button.dart';

class LearningPlanSchedulePage extends StatefulWidget {
  final LearningPlanCourse course;

  const LearningPlanSchedulePage({
    Key? key,
    required this.course,
  }) : super(key: key);

  @override
  State<LearningPlanSchedulePage> createState() => _LearningPlanSchedulePageState();
}

class _LearningPlanSchedulePageState extends State<LearningPlanSchedulePage> {
  final List<String> _times = const ['10:00 AM', '02:00 PM', '07:30 PM'];
  String _selectedTime = '10:00 AM';

  void _saveReminder() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reminder set for $_selectedTime',
        ),
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
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Schedule',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text(
            widget.course.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'OpenSans',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose a daily reminder time.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontFamily: 'OpenSans',
            ),
          ),
          const SizedBox(height: 16),
          ..._times.map(
            (time) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: AppColors.background,
                leading: Icon(
                  _selectedTime == time
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: AppColors.primary,
                ),
                title: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'OpenSans',
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedTime = time;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            text: 'Save reminder',
            onPressed: _saveReminder,
          ),
        ],
      ),
    );
  }
}

