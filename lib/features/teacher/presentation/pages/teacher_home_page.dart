import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/user_display_name.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../widgets/teacher_bottom_nav.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({Key? key}) : super(key: key);

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  int _currentNavIndex = 0;
  final ApiClient _apiClient = ApiClient();
  bool _isLoadingStats = false;
  bool _isLoadingCourses = false;
  bool _isLoadingEarnings = false;
  bool _isLoadingStudents = false;
  int _activeCourses = 0;
  int _studentsEnrolled = 0;
  int _completionRate = 0;
  List<_CourseInfo> _courses = [];
  List<_StudentInfo> _studentLogins = [];
  String _monthlyEarnings = 'Rs 0';
  String _pendingEarnings = 'Rs 0';
  String _lastMonthEarnings = 'Rs 0';

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    switch (index) {
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherCourses);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherSearch);
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherMessages);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherAccount);
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  String _teacherDisplayName() {
    final rawName = HiveService.currentUserName;
    if (rawName == null || rawName.trim().isEmpty) {
      return 'Teacher';
    }
    return displayNameFromUser(rawName);
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([
      _loadCourses(),
      _loadStats(),
      _loadEarnings(),
      _loadStudentLogins(),
    ]);
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final currentName = HiveService.currentUserName;
      final query = (currentName != null && currentName.trim().isNotEmpty)
          ? '?instructor=${Uri.encodeComponent(currentName)}'
          : '';
      final response = await _apiClient.getJson(
        '/api/v1/courses$query',
        token: HiveService.authToken,
      );
      final data = response['data'];
      if (data is List) {
        final mapped = data.map<_CourseInfo>((item) {
          final course = item is Map<String, dynamic> ? item : <String, dynamic>{};
          final lessonCount = course['lessonCount'];
          final total = lessonCount is num && lessonCount > 0 ? lessonCount.toInt() : 1;
          final duration = course['durationHours'];
          final durationValue = duration is num ? duration.toInt() : 0;
          return _CourseInfo(
            title: course['title']?.toString() ?? 'Untitled course',
            subtitle: course['description']?.toString() ?? '',
            level: course['category']?.toString() ?? 'General',
            mentor: course['instructorName']?.toString() ?? 'Instructor',
            weeks: durationValue,
            completed: 0,
            total: total,
            status: course['isNew'] == true ? 'New' : 'Active',
            students: 0,
          );
        }).toList();
        if (!mounted) {
          return;
        }
        setState(() {
          _courses = mapped;
          _activeCourses = mapped.length;
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _courses = [];
        _activeCourses = 0;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCourses = false;
        });
      }
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final token = HiveService.authToken;
      if (token == null || token.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _studentsEnrolled = 0;
          _completionRate = 0;
        });
        return;
      }

      final tutorStudentsResponse = await _apiClient.getJson(
        '/api/v1/tutor-students?status=active',
        token: token,
      );
      final tutorStudentsData = tutorStudentsResponse['data'];
      final enrolledCount = tutorStudentsData is List ? tutorStudentsData.length : 0;

      final enrollmentsResponse = await _apiClient.getJson(
        '/api/v1/enrollments',
        token: token,
      );
      final enrollmentsData = enrollmentsResponse['data'];
      int enrollmentCount = 0;
      double totalProgress = 0;
      if (enrollmentsData is List) {
        for (final entry in enrollmentsData) {
          if (entry is! Map<String, dynamic>) {
            continue;
          }
          final progress = entry['progressPercent'];
          if (progress is num) {
            totalProgress += progress.toDouble();
          }
          enrollmentCount += 1;
        }
      }

      final completion = enrollmentCount == 0
          ? 0
          : (totalProgress / enrollmentCount).round();

      if (!mounted) {
        return;
      }
      setState(() {
        _studentsEnrolled = enrolledCount;
        _completionRate = completion;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _studentsEnrolled = 0;
        _completionRate = 0;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _loadEarnings() async {
    setState(() {
      _isLoadingEarnings = true;
    });

    try {
      final token = HiveService.authToken;
      if (token == null || token.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _monthlyEarnings = 'Rs 0';
          _pendingEarnings = 'Rs 0';
          _lastMonthEarnings = 'Rs 0';
        });
        return;
      }

      final response = await _apiClient.getJson(
        '/api/v1/payments/summary',
        token: token,
      );
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        final thisMonth = data['thisMonth'];
        final pending = data['pending'];
        final lastMonth = data['lastMonth'];
        final thisMonthValue = thisMonth is num ? thisMonth.toDouble() : 0.0;
        final pendingValue = pending is num ? pending.toDouble() : 0.0;
        final lastMonthValue = lastMonth is num ? lastMonth.toDouble() : 0.0;
        if (!mounted) {
          return;
        }
        setState(() {
          _monthlyEarnings = _formatCurrency(thisMonthValue);
          _pendingEarnings = _formatCurrency(pendingValue);
          _lastMonthEarnings = _formatCurrency(lastMonthValue);
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _monthlyEarnings = 'Rs 0';
        _pendingEarnings = 'Rs 0';
        _lastMonthEarnings = 'Rs 0';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEarnings = false;
        });
      }
    }
  }

  Future<void> _loadStudentLogins() async {
    setState(() {
      _isLoadingStudents = true;
    });

    try {
      final response = await _apiClient.getJson(
        '/api/v1/teacher-requests',
        token: HiveService.authToken,
      );
      final data = response['data'];
      if (data is List) {
        final mapped = data
            .whereType<Map<String, dynamic>>()
            .map(_StudentInfo.fromRequest)
            .where((item) => item.status == 'Accepted')
            .toList();
        if (!mounted) {
          return;
        }
        setState(() {
          _studentLogins = mapped;
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _studentLogins = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStudents = false;
        });
      }
    }
  }

  String _formatCurrency(double value) {
    final rounded = value.round().toString();
    final formatted = rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return 'Rs $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _teacherDisplayName();
    final courses = _courses;

    final students = _studentLogins;

    return Scaffold(
      backgroundColor: AppColors.teacherBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.teacherPrimaryDark),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.teacherHome,
            (route) => false,
          ),
        ),
        title: const Text(
          'Teacher Dashboard',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.teacherPrimaryDark,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                _DashboardHeader(
                  displayName: displayName,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.teacherReports),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = (constraints.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _StatCard(
                            title: 'Courses',
                            value: _isLoadingStats ? '...' : '$_activeCourses',
                            subtitle: 'Active',
                            icon: Icons.menu_book,
                            isExpanded: false,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _StatCard(
                            title: 'Students',
                            value: _isLoadingStats ? '...' : '$_studentsEnrolled',
                            subtitle: 'Enrolled',
                            icon: Icons.people,
                            isExpanded: false,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _StatCard(
                            title: 'Completion',
                            value: _isLoadingStats ? '...' : '$_completionRate%',
                            subtitle: 'This month',
                            icon: Icons.stacked_line_chart,
                            isExpanded: false,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                _EarningsCard(
                  monthly: _isLoadingEarnings ? '...' : _monthlyEarnings,
                  pending: _isLoadingEarnings ? '...' : _pendingEarnings,
                  lastMonth: _isLoadingEarnings ? '...' : _lastMonthEarnings,
                ),
                const SizedBox(height: 20),
                const _SectionHeader(title: 'Quick actions'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ActionChip(
                      label: 'Create course',
                      icon: Icons.add_box,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.teacherCreateCourse),
                    ),
                    _ActionChip(
                      label: 'Schedule session',
                      icon: Icons.schedule,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.teacherScheduleSession),
                    ),
                    _ActionChip(
                      label: 'Review requests',
                      icon: Icons.inbox,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.teacherRequests),
                    ),
                    _ActionChip(
                      label: 'Manage students',
                      icon: Icons.group,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.teacherManageStudents),
                    ),
                    _ActionChip(
                      label: 'Share invite',
                      icon: Icons.campaign,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.teacherShareInvite),
                    ),
                    _ActionChip(
                      label: 'Payout settings',
                      icon: Icons.account_balance_wallet,
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.teacherPayoutSettings),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Courses (${courses.length})',
                  actionLabel: 'View all',
                  onActionTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.teacherCourseOverview),
                ),
                const SizedBox(height: 12),
                if (_isLoadingCourses)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                SizedBox(
                  height: 154,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: courses.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => _CourseCard(
                      info: courses[index],
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.teacherCourseDetail,
                        arguments: courses[index].toMap(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _SectionHeader(
                  title: 'Student logins',
                  actionLabel: 'View all',
                  onActionTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.teacherStudentLogins),
                ),
                const SizedBox(height: 12),
                if (_isLoadingStudents)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (!_isLoadingStudents && students.isEmpty)
                  const Text(
                    'No accepted requests yet.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.teacherMuted,
                      fontFamily: 'Inter',
                    ),
                  ),
                if (!_isLoadingStudents)
                  ...students.map(
                    (student) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _StudentTile(
                        info: student,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.teacherStudentProfile,
                          arguments: student.toMap(),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.teacherProfessionals);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.teacherGradientStart,
                          AppColors.teacherGradientEnd,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.teacherSurface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.people_outline,
                            color: AppColors.teacherPrimaryDark,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connect with professionals',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.teacherSurface,
                                  fontFamily: 'Inter',
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Find experts, mentors, and co-teachers',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.teacherSurface,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.teacherSurface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text(
                            'Explore',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.teacherPrimaryDark,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          TeacherBottomNav(
            currentIndex: _currentNavIndex,
            onTap: _onNavTap,
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final VoidCallback onTap;
  final String displayName;

  const _DashboardHeader({
    required this.onTap,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            AppColors.teacherGradientStart,
            AppColors.teacherGradientEnd,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, $displayName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.teacherSurface,
                    fontFamily: 'Inter',
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'You have 3 sessions today and 8 new requests.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.teacherSurface,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.teacherSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'View report',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.teacherPrimaryDark,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.teacherPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
      ],
    );
  }
}

class _EarningsCard extends StatelessWidget {
  final String monthly;
  final String pending;
  final String lastMonth;

  const _EarningsCard({
    required this.monthly,
    required this.pending,
    required this.lastMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.teacherSurface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Earnings',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.teacherMuted,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            monthly,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.teacherPrimaryDark,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _EarningStat(label: 'Pending', value: pending),
              const SizedBox(width: 12),
              _EarningStat(label: 'Last month', value: lastMonth),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarningStat extends StatelessWidget {
  final String label;
  final String value;

  const _EarningStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.teacherSurfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.teacherMuted,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool isWide;
  final bool isExpanded;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.isWide = false,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.teacherSurface,
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.teacherChip,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.teacherPrimaryDark),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.teacherMuted,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.teacherMuted,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (isWide || !isExpanded) {
      return content;
    }

    return Expanded(child: content);
  }
}

class _CourseInfo {
  final String title;
  final String subtitle;
  final String level;
  final String mentor;
  final int weeks;
  final int completed;
  final int total;
  final String status;
  final int students;

  const _CourseInfo({
    required this.title,
    required this.subtitle,
    required this.level,
    required this.mentor,
    required this.weeks,
    required this.completed,
    required this.total,
    required this.status,
    required this.students,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'level': level,
      'mentor': mentor,
      'weeks': '$weeks weeks',
      'progress': '$completed / $total',
      'status': status,
      'students': '$students students',
    };
  }
}

class _CourseCard extends StatelessWidget {
  final _CourseInfo info;
  final VoidCallback onTap;

  const _CourseCard({
    required this.info,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.teacherSurface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TagChip(label: info.status),
            const SizedBox(height: 10),
            Text(
              info.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 6),
              Text(
                info.subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.teacherMuted,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${info.level} - ${info.mentor}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.teacherMuted,
                  fontFamily: 'Inter',
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.people, size: 16, color: AppColors.teacherMuted),
                  const SizedBox(width: 6),
                  Text(
                    '${info.students} students',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.teacherMuted,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${info.completed}/${info.total}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.teacherMuted,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;

  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.teacherChip,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.teacherPrimaryDark,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class _StudentInfo {
  final String name;
  final String course;
  final String status;
  final String lastActive;

  const _StudentInfo({
    required this.name,
    required this.course,
    required this.status,
    required this.lastActive,
  });

  static _StudentInfo fromRequest(Map<String, dynamic> json) {
    final student = json['student'];
    final studentMap = student is Map<String, dynamic> ? student : <String, dynamic>{};
    final course = json['course'];
    final courseMap = course is Map<String, dynamic> ? course : <String, dynamic>{};
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    final lastActive = createdAt == null ? 'Accepted' : _formatDate(createdAt);
    return _StudentInfo(
      name: studentMap['name']?.toString() ?? 'Student',
      course: courseMap['title']?.toString() ?? 'Course',
      status: json['status']?.toString() == 'accepted' ? 'Accepted' : 'Pending',
      lastActive: lastActive,
    );
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$month/$day $hour:$minute';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'course': course,
      'status': status,
      'lastActive': lastActive,
    };
  }
}

class _StudentTile extends StatelessWidget {
  final _StudentInfo info;
  final VoidCallback onTap;

  const _StudentTile({
    required this.info,
    required this.onTap,
  });

  Color _statusColor() {
    switch (info.status) {
      case 'Accepted':
        return AppColors.teacherPrimary;
      case 'Online':
        return AppColors.teacherPrimary;
      case 'Recent':
        return AppColors.teacherAccent;
      default:
        return AppColors.teacherMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.teacherSurface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.teacherChip,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  info.name.substring(0, 1),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info.course,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.teacherMuted,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  info.lastActive,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.teacherMuted,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    info.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.teacherSurfaceAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.teacherPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

