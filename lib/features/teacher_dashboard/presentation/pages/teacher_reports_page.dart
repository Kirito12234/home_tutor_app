import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';

class TeacherReportsPage extends StatefulWidget {
  const TeacherReportsPage({super.key});

  @override
  State<TeacherReportsPage> createState() => _TeacherReportsPageState();
}

class _TeacherReportsPageState extends State<TeacherReportsPage> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  bool _isDownloading = false;
  String? _errorMessage;
  _ReportData _report = _ReportData.empty();
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadReports();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadReports(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadReports() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Please log in to view reports.';
          _report = _ReportData.empty();
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final currentName = HiveService.currentUserName;
    final instructorQuery = (currentName != null && currentName.trim().isNotEmpty)
        ? '?instructor=${Uri.encodeComponent(currentName)}'
        : '';

    List<Map<String, dynamic>> courses = const <Map<String, dynamic>>[];
    List<Map<String, dynamic>> sessions = const <Map<String, dynamic>>[];
    List<Map<String, dynamic>> requests = const <Map<String, dynamic>>[];
    List<Map<String, dynamic>> enrollments = const <Map<String, dynamic>>[];
    Map<String, dynamic> paymentSummary = const <String, dynamic>{};

    Future<void> loadCourses() async {
      final response = await _apiClient.getJson(
        '/api/v1/courses$instructorQuery',
        token: token,
      );
      final data = response['data'];
      if (data is List) {
        courses = data.whereType<Map<String, dynamic>>().toList();
      }
    }

    Future<void> loadSessions() async {
      final response = await _apiClient.getJson(
        '/api/v1/sessions',
        token: token,
      );
      final data = response['data'];
      if (data is List) {
        sessions = data.whereType<Map<String, dynamic>>().toList();
      }
    }

    Future<void> loadRequests() async {
      final response = await _apiClient.getJson(
        '/api/v1/teacher-requests',
        token: token,
      );
      final data = response['data'];
      if (data is List) {
        requests = data.whereType<Map<String, dynamic>>().toList();
      }
    }

    Future<void> loadEnrollments() async {
      final response = await _apiClient.getJson(
        '/api/v1/enrollments',
        token: token,
      );
      final data = response['data'];
      if (data is List) {
        enrollments = data.whereType<Map<String, dynamic>>().toList();
      }
    }

    Future<void> loadPaymentSummary() async {
      final response = await _apiClient.getJson(
        '/api/v1/payments/summary',
        token: token,
      );
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        paymentSummary = data;
      }
    }

    try {
      await Future.wait<void>([
        loadCourses(),
        loadSessions(),
        loadRequests(),
        loadEnrollments(),
        loadPaymentSummary(),
      ]);

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final previousWeekStart = weekStart.subtract(const Duration(days: 7));
      final previousWeekEnd = weekStart.subtract(const Duration(milliseconds: 1));

      final newCoursesThisWeek = courses.where((course) {
        final createdAt = DateTime.tryParse(course['createdAt']?.toString() ?? '');
        return createdAt != null && createdAt.isAfter(weekStart);
      }).length;

      final completedSessionsThisWeek = sessions.where((session) {
        final status = session['status']?.toString().toLowerCase() ?? '';
        final startTime = DateTime.tryParse(session['startTime']?.toString() ?? '');
        if (startTime == null || !startTime.isAfter(weekStart)) {
          return false;
        }
        return status == 'completed';
      }).length;

      int currentWeekAccepted = 0;
      int previousWeekAccepted = 0;
      for (final request in requests) {
        final status = request['status']?.toString().toLowerCase() ?? '';
        if (status != 'accepted') {
          continue;
        }
        final createdAt = DateTime.tryParse(request['createdAt']?.toString() ?? '');
        if (createdAt == null) {
          continue;
        }
        if (createdAt.isAfter(weekStart)) {
          currentWeekAccepted += 1;
        } else if (createdAt.isAfter(previousWeekStart) && createdAt.isBefore(previousWeekEnd)) {
          previousWeekAccepted += 1;
        }
      }
      final growthPercent = previousWeekAccepted == 0
          ? (currentWeekAccepted > 0 ? 100.0 : 0.0)
          : ((currentWeekAccepted - previousWeekAccepted) / previousWeekAccepted) * 100;

      final teacherCourseIds = courses
          .map((course) => course['_id']?.toString() ?? course['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();

      final teacherEnrollments = enrollments.where((enrollment) {
        final course = enrollment['course'];
        final courseMap = course is Map<String, dynamic> ? course : <String, dynamic>{};
        final courseId = courseMap['_id']?.toString() ?? courseMap['id']?.toString() ?? '';
        return teacherCourseIds.contains(courseId);
      }).toList();

      double totalProgress = 0;
      int progressCount = 0;
      for (final enrollment in teacherEnrollments) {
        final progress = enrollment['progressPercent'];
        if (progress is num) {
          totalProgress += progress.toDouble();
          progressCount += 1;
        }
      }
      final completionRate = progressCount == 0 ? 0 : (totalProgress / progressCount).round();

      final enrollmentsByCourse = <String, int>{};
      for (final enrollment in teacherEnrollments) {
        final course = enrollment['course'];
        final courseMap = course is Map<String, dynamic> ? course : <String, dynamic>{};
        final courseTitle = courseMap['title']?.toString() ?? 'Course';
        enrollmentsByCourse[courseTitle] = (enrollmentsByCourse[courseTitle] ?? 0) + 1;
      }
      String topCourseName = 'N/A';
      int topCourseStudents = 0;
      enrollmentsByCourse.forEach((title, count) {
        if (count > topCourseStudents) {
          topCourseStudents = count;
          topCourseName = title;
        }
      });

      final hourCount = <int, int>{};
      for (final session in sessions) {
        final startTime = DateTime.tryParse(session['startTime']?.toString() ?? '');
        if (startTime == null) {
          continue;
        }
        final hour = startTime.toLocal().hour;
        hourCount[hour] = (hourCount[hour] ?? 0) + 1;
      }
      int peakHour = 0;
      int peakHourSessions = 0;
      hourCount.forEach((hour, count) {
        if (count > peakHourSessions) {
          peakHour = hour;
          peakHourSessions = count;
        }
      });
      final peakRange = '${_formatHour(peakHour)} - ${_formatHour((peakHour + 3) % 24)}';
      final peakRatio = sessions.isEmpty ? 0 : ((peakHourSessions / sessions.length) * 100).round();

      int ratingCount = 0;
      double ratingTotal = 0;
      for (final course in courses) {
        final rating = course['rating'];
        if (rating is num) {
          ratingTotal += rating.toDouble();
          ratingCount += 1;
        }
      }
      final double avgRating =
          ratingCount == 0 ? 0.0 : (ratingTotal / ratingCount);

      final thisMonth = (paymentSummary['thisMonth'] as num?)?.toDouble() ?? 0.0;

      if (!mounted) {
        return;
      }
      setState(() {
        _report = _ReportData(
          weeklyRevenue: _formatCurrency(thisMonth),
          newCoursesThisWeek: newCoursesThisWeek,
          completedSessionsThisWeek: completedSessionsThisWeek,
          studentGrowthPercent: growthPercent.toDouble(),
          newEnrollmentsThisWeek: currentWeekAccepted,
          completionRate: completionRate,
          topCourseName: topCourseName,
          topCourseStudents: topCourseStudents,
          peakHoursRange: peakRange,
          peakSessionSharePercent: peakRatio,
          averageRating: avgRating,
          ratedCourseCount: ratingCount,
          generatedAt: DateTime.now(),
        );
      });
    } on HttpException catch (err) {
      if (mounted) {
        setState(() {
          _errorMessage = err.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load reports.';
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

  String _formatCurrency(double value) {
    final rounded = value.round().toString();
    final formatted = rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return 'Rs $formatted';
  }

  String _formatHour(int hour24) {
    final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    return '$hour:00 $period';
  }

  Future<void> _downloadReportCsv() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final data = _report;
      final csv = StringBuffer()
        ..writeln('metric,value')
        ..writeln('generated_at,${data.generatedAt.toIso8601String()}')
        ..writeln('weekly_revenue,${data.weeklyRevenue}')
        ..writeln('new_courses_this_week,${data.newCoursesThisWeek}')
        ..writeln('completed_sessions_this_week,${data.completedSessionsThisWeek}')
        ..writeln('student_growth_percent,${data.studentGrowthPercent.toStringAsFixed(1)}')
        ..writeln('new_enrollments_this_week,${data.newEnrollmentsThisWeek}')
        ..writeln('completion_rate_percent,${data.completionRate}')
        ..writeln('top_course,${data.topCourseName}')
        ..writeln('top_course_students,${data.topCourseStudents}')
        ..writeln('peak_hours,${data.peakHoursRange}')
        ..writeln('peak_session_share_percent,${data.peakSessionSharePercent}')
        ..writeln('average_rating,${data.averageRating.toStringAsFixed(1)}')
        ..writeln('rated_course_count,${data.ratedCourseCount}');

      if (kIsWeb) {
        if (!mounted) {
          return;
        }
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Report CSV'),
            content: const Text(
              'Download to file is not available in this build. Use mobile/desktop app for file save.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'teacher_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(csv.toString());

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report downloaded: ${file.path}')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to download report.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
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
          'Reports',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'OpenSans',
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isDownloading ? null : _downloadReportCsv,
            icon: _isDownloading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download, size: 18),
            label: const Text('Download'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: LinearProgressIndicator(minHeight: 2),
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.redAccent,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
            _ReportCard(
              title: 'Weekly summary',
              subtitle:
                  '${report.newCoursesThisWeek} new courses, ${report.completedSessionsThisWeek} sessions completed',
              value: report.weeklyRevenue,
            ),
            const SizedBox(height: 14),
            _ReportCard(
              title: 'Student growth',
              subtitle: '${report.newEnrollmentsThisWeek} new enrollments this week',
              value:
                  '${report.studentGrowthPercent >= 0 ? '+' : ''}${report.studentGrowthPercent.toStringAsFixed(1)}%',
            ),
            const SizedBox(height: 14),
            _ReportCard(
              title: 'Completion rate',
              subtitle: 'Average progress across courses',
              value: '${report.completionRate}%',
            ),
            const SizedBox(height: 20),
            const Text(
              'Insights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: 'OpenSans',
              ),
            ),
            const SizedBox(height: 12),
            _InsightTile(
              title: 'Top course',
              value: report.topCourseName,
              detail: '${report.topCourseStudents} active students',
            ),
            const SizedBox(height: 10),
            _InsightTile(
              title: 'Peak hours',
              value: report.peakHoursRange,
              detail: '${report.peakSessionSharePercent}% of sessions',
            ),
            const SizedBox(height: 10),
            _InsightTile(
              title: 'Best ratings',
              value: '${report.averageRating.toStringAsFixed(1)} average',
              detail: 'Across ${report.ratedCourseCount} rated courses',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportData {
  const _ReportData({
    required this.weeklyRevenue,
    required this.newCoursesThisWeek,
    required this.completedSessionsThisWeek,
    required this.studentGrowthPercent,
    required this.newEnrollmentsThisWeek,
    required this.completionRate,
    required this.topCourseName,
    required this.topCourseStudents,
    required this.peakHoursRange,
    required this.peakSessionSharePercent,
    required this.averageRating,
    required this.ratedCourseCount,
    required this.generatedAt,
  });

  _ReportData.empty()
      : weeklyRevenue = 'Rs 0',
        newCoursesThisWeek = 0,
        completedSessionsThisWeek = 0,
        studentGrowthPercent = 0.0,
        newEnrollmentsThisWeek = 0,
        completionRate = 0,
        topCourseName = 'N/A',
        topCourseStudents = 0,
        peakHoursRange = 'N/A',
        peakSessionSharePercent = 0,
        averageRating = 0.0,
        ratedCourseCount = 0,
        generatedAt = DateTime.fromMillisecondsSinceEpoch(0);

  final String weeklyRevenue;
  final int newCoursesThisWeek;
  final int completedSessionsThisWeek;
  final double studentGrowthPercent;
  final int newEnrollmentsThisWeek;
  final int completionRate;
  final String topCourseName;
  final int topCourseStudents;
  final String peakHoursRange;
  final int peakSessionSharePercent;
  final double averageRating;
  final int ratedCourseCount;
  final DateTime generatedAt;
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            child: const Icon(Icons.analytics, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'OpenSans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'OpenSans',
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.title,
    required this.value,
    required this.detail,
  });

  final String title;
  final String value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    fontFamily: 'OpenSans',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: 'OpenSans',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textLight),
        ],
      ),
    );
  }
}


