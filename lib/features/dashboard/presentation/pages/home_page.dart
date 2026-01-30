import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../widgets/header_greeting.dart';
import '../widgets/learned_today_card.dart';
import '../widgets/learn_banner_card.dart';
import '../widgets/learning_plan_card.dart';
import '../widgets/bottom_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    switch (index) {
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.courses);
        break;
      case 2:
        Navigator.of(context).pushNamed(AppRoutes.searchResults);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.notifications);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.account);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderGreeting(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const LearnedTodayCard(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          LearnBannerCard(
                            isLeft: true,
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRoutes.learnToday);
                            },
                          ),
                          LearnBannerCard(
                            isLeft: false,
                            onTap: () {
                              Navigator.of(context).pushNamed(AppRoutes.learnToday);
                            },
                          ),
                        ],
                      ),
                    ),
                    const LearningPlanCard(),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed(AppRoutes.meetup);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.categoryPurple,
                              AppColors.categoryPurple.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people,
                              size: 40,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Meetup',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Join the community',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            BottomNav(
              currentIndex: _currentNavIndex,
              onTap: _onNavTap,
            ),
          ],
        ),
      ),
    );
  }
}

