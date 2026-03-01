import 'package:flutter/material.dart';
import '../../../../../app/routes/app_routes.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/widgets/page_dots.dart';
import '../../../../../core/services/hive/hive_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedRole;
  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Numerous free\ntrial courses',
      subtitle: 'Free courses for you to\nfind your way to learning',
      showSkip: true,
    ),
    OnboardingData(
      title: 'Quick and easy\nlearning',
      subtitle: 'Easy and fast learning at\nany time to help you improve various skills',
      showSkip: true,
    ),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _skipOnboarding() async {
    await HiveService.setOnboardingDone(true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            if (_pages[_currentPage].showSkip)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            if (_currentPage == 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _RoleOption(
                        title: 'Student',
                        icon: Icons.school,
                        isSelected: _selectedRole == 'student',
                        onTap: () async {
                          setState(() {
                            _selectedRole = 'student';
                          });
                          await HiveService.setCurrentUserRole('student');
                          if (mounted) {
                            await HiveService.setOnboardingDone(true);
                            Navigator.of(context).pushReplacementNamed(
                              AppRoutes.login,
                              arguments: 'student',
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleOption(
                        title: 'Teacher',
                        icon: Icons.person,
                        isSelected: _selectedRole != 'student',
                        onTap: () async {
                          setState(() {
                            _selectedRole = 'teacher';
                          });
                          await HiveService.setCurrentUserRole('teacher');
                          if (mounted) {
                            await HiveService.setOnboardingDone(true);
                            Navigator.of(context).pushReplacementNamed(
                              AppRoutes.login,
                              arguments: 'teacher',
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PageDots(
                currentIndex: _currentPage,
                totalPages: _pages.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageHeight = (constraints.maxHeight * 0.45).clamp(200.0, 300.0);
        final topSpacing = (constraints.maxHeight * 0.05).clamp(16.0, 40.0);
        final betweenSpacing = (constraints.maxHeight * 0.05).clamp(24.0, 48.0);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: topSpacing),
              Container(
                width: double.infinity,
                height: imageHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Icon(
                    Icons.school,
                    size: 120,
                    color: AppColors.primary.withOpacity(0.6),
                  ),
                ),
              ),
              SizedBox(height: betweenSpacing),
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'OpenSans',
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  fontFamily: 'OpenSans',
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final bool showSkip;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.showSkip,
  });
}

class _RoleOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isSelected ? AppColors.buttonText : AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.buttonText : AppColors.primary,
            fontFamily: 'OpenSans',
          ),
        ),
      ],
    );

    if (isSelected) {
      return SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.buttonText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: child,
      ),
    );
  }
}


