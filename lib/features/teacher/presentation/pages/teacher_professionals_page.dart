import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/user_display_name.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../widgets/teacher_bottom_nav.dart';

class TeacherProfessionalsPage extends StatefulWidget {
  const TeacherProfessionalsPage({Key? key}) : super(key: key);

  @override
  State<TeacherProfessionalsPage> createState() => _TeacherProfessionalsPageState();
}

class _TeacherProfessionalsPageState extends State<TeacherProfessionalsPage> {
  int _currentNavIndex = 0;
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, String>> _pros = [];
  bool _isClearing = false;

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherHome);
        break;
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

  void _showAction(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProfessionals();
  }

  Future<void> _loadProfessionals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getJson('/api/v1/professionals');
      final data = response['data'];
      if (data is List) {
        final mapped = data
            .whereType<Map<String, dynamic>>()
            .map((profile) {
              final user = profile['user'];
              final userMap = user is Map<String, dynamic> ? user : <String, dynamic>{};
              final name = userMap['name']?.toString() ?? 'Professional';
              final subjects = profile['subjects'];
              final subjectNames = subjects is List
                  ? subjects
                      .whereType<Map<String, dynamic>>()
                      .map((item) => item['title']?.toString())
                      .whereType<String>()
                      .toList()
                  : <String>[];
              final role = subjectNames.isNotEmpty ? subjectNames.join(', ') : 'Tutor';
              final location = profile['location']?.toString() ?? 'Remote';
              return {
                'name': name,
                'role': role,
                'company': location,
              };
            })
            .toList();
        setState(() {
          _pros = mapped;
        });
      } else {
        setState(() {
          _errorMessage = 'Unexpected response format.';
        });
      }
    } on HttpException catch (err) {
      setState(() {
        _errorMessage = err.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unable to load professionals.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _clearAndReload() async {
    if (_isClearing) {
      return;
    }
    setState(() {
      _isClearing = true;
      _pros = [];
      _errorMessage = null;
    });
    await _loadProfessionals();
    if (mounted) {
      setState(() {
        _isClearing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawName = HiveService.currentUserName;
    final displayName = (rawName == null || rawName.trim().isEmpty)
        ? 'Teacher'
        : displayNameFromUser(rawName);
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
          'Professionals',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        actions: [
          TextButton(
            onPressed: _clearAndReload,
            child: const Text('Clear'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.redAccent,
                            fontFamily: 'Inter',
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: AppColors.categoryBlue,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Teacher',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        displayName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: _clearAndReload,
                                  child: const Text('Refresh'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_pros.isEmpty)
                            const Text(
                              'No professionals found.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ..._pros.map((pro) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: AppColors.categoryBlue,
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              pro['name'] ?? 'Professional',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${pro['role'] ?? 'Tutor'} - ${pro['company'] ?? 'Remote'}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => _showAction('Invited ${pro['name']}'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          side: const BorderSide(color: AppColors.primary),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                          'Invite',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: () => _showAction('Messaging ${pro['name']}'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.textSecondary,
                                          side: const BorderSide(color: AppColors.textSecondary),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                          'Message',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      ElevatedButton(
                                        onPressed: () =>
                                            _showAction('Collaborating with ${pro['name']}'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: AppColors.buttonText,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: const Text(
                                          'Collaborate',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Inter',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
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


