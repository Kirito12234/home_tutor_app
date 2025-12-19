import 'package:flutter/material.dart';
import 'my_courses_screen.dart';
import 'get_started_screen.dart';
import 'packaging_design_screen.dart';
import 'product_design_screen.dart';
import 'meetup_screen.dart';
import 'profile_screen.dart';
import 'course_screen.dart';
import 'search_screen.dart';
import 'message_screen.dart';
import 'account_screen.dart';
import 'settings_screen.dart';
import 'help_support_screen.dart';
import 'java_course_screen.dart';
import 'python_course_screen.dart';
import 'painting_course_screen.dart';
import 'react_course_screen.dart';
import 'web_development_course_screen.dart';
import 'flutter_course_screen.dart';
import 'machine_learning_course_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Home'),
      ),
      drawer: _buildDrawer(context),
      body: _buildDashboardHome(context),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF3366FF),
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          currentIndex: 0,
          onTap: (index) {
            switch (index) {
              case 0:
                // Already on Home, do nothing
                break;
              case 1:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CourseScreen(),
                  ),
                );
                break;
              case 2:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SearchScreen(),
                  ),
                );
                break;
              case 3:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MessageScreen(),
                  ),
                );
                break;
              case 4:
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccountScreen(),
                  ),
                );
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded),
              label: 'Course',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message_rounded),
              label: 'Message',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHome(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildTodayCard(context),
            const SizedBox(height: 20),
            _buildWhatToLearnSection(context),
            const SizedBox(height: 24),
            const Text(
              'Learning Plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildLearningPlanList(context),
            const SizedBox(height: 24),
            _buildMeetupCard(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3366FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, Shreedhar',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Let's start learning",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFE0ECFF),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProfileScreen(),
                ),
              );
            },
            child: const CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                color: Color(0xFF3366FF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Learned today',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyCoursesScreen(),
                    ),
                  );
                },
                child: const Text(
                  'My courses',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3366FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: '46min ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: '/ 60min',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(40),
            child: const LinearProgressIndicator(
              value: 46 / 60,
              backgroundColor: Color(0xFFE9EDF5),
              valueColor: AlwaysStoppedAnimation(Color(0xFFFFA726)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatToLearnSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What do you want\nto learn today?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const GetStartedScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7043),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Icon(
                  Icons.school,
                  size: 40,
                  color: Color(0xFF3366FF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPlanList(BuildContext context) {
    final courses = _getCourses();
    
    return SizedBox(
      height: 400, // Fixed height for scrollable list
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildLearningPlanCard(
              context: context,
              title: course['title'] as String,
              progressText: course['progressText'] as String,
              progress: course['progress'] as double,
              isPrimary: course['isPrimary'] as bool,
              screen: course['screen'] as Widget,
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getCourses() {
    return [
      {
        'title': 'Packaging Design',
        'progressText': '40/48',
        'progress': 40 / 48,
        'isPrimary': true,
        'screen': const PackagingDesignScreen(),
      },
      {
        'title': 'Product Design',
        'progressText': '6/24',
        'progress': 6 / 24,
        'isPrimary': false,
        'screen': const ProductDesignScreen(),
      },
      {
        'title': 'Java Programming',
        'progressText': '25/30',
        'progress': 25 / 30,
        'isPrimary': true,
        'screen': const JavaCourseScreen(),
      },
      {
        'title': 'Python Programming',
        'progressText': '18/25',
        'progress': 18 / 25,
        'isPrimary': true,
        'screen': const PythonCourseScreen(),
      },
      {
        'title': 'Painting',
        'progressText': '12/20',
        'progress': 12 / 20,
        'isPrimary': false,
        'screen': const PaintingCourseScreen(),
      },
      {
        'title': 'React Development',
        'progressText': '30/35',
        'progress': 30 / 35,
        'isPrimary': true,
        'screen': const ReactCourseScreen(),
      },
      {
        'title': 'Web Development',
        'progressText': '22/28',
        'progress': 22 / 28,
        'isPrimary': true,
        'screen': const WebDevelopmentCourseScreen(),
      },
      {
        'title': 'Flutter Development',
        'progressText': '15/20',
        'progress': 15 / 20,
        'isPrimary': true,
        'screen': const FlutterCourseScreen(),
      },
      {
        'title': 'Machine Learning',
        'progressText': '8/15',
        'progress': 8 / 15,
        'isPrimary': false,
        'screen': const MachineLearningCourseScreen(),
      },
    ];
  }

  Widget _buildLearningPlanCard({
    required BuildContext context,
    required String title,
    required String progressText,
    required double progress,
    required bool isPrimary,
    required Widget screen,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: const Color(0xFFE9EDF5),
                    valueColor: AlwaysStoppedAnimation(
                      isPrimary
                          ? const Color(0xFF3366FF)
                          : const Color(0xFFB0BEC5),
                    ),
                  ),
                  Icon(
                    Icons.play_arrow_rounded,
                    size: 20,
                    color: isPrimary ? const Color(0xFF3366FF) : Colors.grey,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progressText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetupCard(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MeetupScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7FF),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Meetup',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A148C),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Off-line exchange of\nlearning experience',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(
                    Icons.groups_rounded,
                    size: 34,
                    color: Color(0xFF7E57C2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
              child: const UserAccountsDrawerHeader(
                accountName: Text('Shreedhar'),
                accountEmail: Text('shreedhar@example.com'),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    color: Color(0xFF3366FF),
                  ),
                ),
                decoration: BoxDecoration(
                  color: Color(0xFF3366FF),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_filled),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HelpSupportScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
