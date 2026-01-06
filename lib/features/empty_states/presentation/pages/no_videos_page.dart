import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../widgets/empty_state_view.dart';

class NoVideosPage extends StatelessWidget {
  const NoVideosPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      title: 'No videos!',
      subtitle: 'Here is no video you want at the moment',
      showBack: true,
      primaryButtonText: 'Search more',
      onPrimaryPressed: () {
        // Navigate to courses/search page
        Navigator.of(context).pushNamed(AppRoutes.courses);
      },
      customIllustration: _buildIllustration(),
    );
  }

  Widget _buildIllustration() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cloud shapes
          Positioned(
            top: 20,
            left: 10,
            child: Container(
              width: 40,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.textLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            right: 15,
            child: Container(
              width: 35,
              height: 25,
              decoration: BoxDecoration(
                color: AppColors.textLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 5,
            child: Container(
              width: 30,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.textLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          // Clapperboard
          Positioned(
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFE8E0FF), // Light purple
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Clapperboard top section
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1C4E9),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  // Play icon
                  const Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      size: 60,
                      color: Color(0xFF9C27B0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Person
          Positioned(
            bottom: 20,
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFF2196F3), // Blue shirt
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

