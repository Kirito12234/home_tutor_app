import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../dashboard/domain/entities/lesson.dart';

class LessonListItem extends StatelessWidget {
  final Lesson lesson;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onMaterialsTap;

  const LessonListItem({
    Key? key,
    required this.lesson,
    this.isPlaying = false,
    this.onTap,
    this.onMaterialsTap,
  }) : super(key: key);

  String _formatDurationShort(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) {
      return '${hours}:${mins.toString().padLeft(2, '0')} mins';
    }
    return '${mins.toString().padLeft(2, '0')} mins';
  }

  @override
  Widget build(BuildContext context) {
    final hasMaterials = lesson.imageUrl != null || lesson.pdfUrl != null;
    return GestureDetector(
      onTap: lesson.isLocked ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lesson.order.toString().padLeft(2, '0'),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.textLight,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: lesson.isLocked
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _formatDurationShort(lesson.durationMinutes),
                        style: TextStyle(
                          fontSize: 12,
                          color: lesson.isCompleted
                              ? AppColors.durationOrange
                              : AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      if (lesson.isCompleted) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: AppColors.durationOrange,
                        ),
                      ],
                      if (hasMaterials) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: lesson.isLocked ? null : onMaterialsTap,
                          child: Row(
                            children: const [
                              Icon(
                                Icons.attachment,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Materials',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: lesson.isLocked ? null : onTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: lesson.isLocked
                      ? AppColors.thumbnailGray
                      : isPlaying
                          ? AppColors.primary
                          : AppColors.primary,
                  shape: BoxShape.circle,
                  border: isPlaying
                      ? Border.all(color: AppColors.durationOrange, width: 2)
                      : null,
                ),
                child: Icon(
                  lesson.isLocked
                      ? Icons.lock
                      : isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                  color: AppColors.buttonText,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

