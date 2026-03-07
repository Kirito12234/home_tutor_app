import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/entities/course.dart';

class CourseListItem extends StatelessWidget {
  final Course course;
  final VoidCallback? onTap;
  final bool showOpenButton;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final String levelLabel;

  const CourseListItem({
    Key? key,
    required this.course,
    this.onTap,
    this.showOpenButton = false,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.levelLabel = 'Beginner',
  }) : super(key: key);

  String _formatPrice(double price) {
    return 'Rs ${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  String _imageUrl(String? input) {
    if (input == null || input.isEmpty) {
      return '';
    }
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return input;
    }
    final base = socketBaseUrl();
    return input.startsWith('/') ? '$base$input' : '$base/$input';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.thumbnailGray,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _imageUrl(course.imageUrl).isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        _imageUrl(course.imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_outlined,
                          size: 20,
                          color: AppColors.textLight,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.image_outlined,
                      size: 20,
                      color: AppColors.textLight,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 33 / 2,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                      fontFamily: 'OpenSans',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    course.instructor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15 / 1.1,
                      color: AppColors.textSecondary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    course.description.isNotEmpty
                        ? course.description
                        : 'No description provided.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    course.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        _formatPrice(course.price),
                        style: const TextStyle(
                          fontSize: 31 / 2,
                          fontWeight: FontWeight.w400,
                          color: AppColors.primary,
                          fontFamily: 'OpenSans',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF3F8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          levelLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontFamily: 'OpenSans',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showOpenButton) ...[
              const SizedBox(width: 8),
              SizedBox(
                width: 82,
                height: 44,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.buttonText,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text(
                    'Open',
                    style: TextStyle(
                      fontSize: 31 / 2,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}



