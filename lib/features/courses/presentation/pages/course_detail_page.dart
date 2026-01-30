import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/api/api_config.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/entities/course.dart';
import '../widgets/lesson_list_item.dart';
import '../../../dashboard/domain/entities/lesson.dart';

class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({Key? key}) : super(key: key);

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  final ApiClient _apiClient = ApiClient();
  Course? _course;
  List<Lesson> _lessons = [];
  bool _isLoading = false;
  bool _isRequesting = false;
  String? _errorMessage;
  bool _didLoad = false;

  String _formatPrice(double price) {
    return 'RS ${price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) {
      return;
    }
    _didLoad = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! Course) {
      setState(() {
        _course = null;
      });
      return;
    }
    setState(() {
      _course = args;
    });
    _loadLessons(args.id);
  }

  Future<void> _loadLessons(String courseId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getJson('/api/v1/courses/$courseId/lessons');
      final data = response['data'];
      if (data is List) {
        final mapped = data
            .whereType<Map<String, dynamic>>()
            .map((lesson) {
              return Lesson(
                id: lesson['_id']?.toString() ?? lesson['id']?.toString() ?? 'lesson',
                title: lesson['title']?.toString() ?? 'Lesson',
                durationMinutes: (lesson['durationMinutes'] as num?)?.toInt() ?? 0,
                isLocked: lesson['isLocked'] == true,
                order: (lesson['order'] as num?)?.toInt() ?? 0,
                imageUrl: lesson['imageUrl']?.toString(),
                pdfUrl: lesson['pdfUrl']?.toString(),
              );
            })
            .toList();
        setState(() {
          _lessons = mapped;
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
        _errorMessage = 'Unable to load lessons.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendTeacherRequest(Course course) async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send request.')),
      );
      Navigator.of(context).pushNamed(AppRoutes.login);
      return;
    }
    if (course.tutorId == null || course.tutorId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Teacher information is missing.')),
      );
      return;
    }

    setState(() {
      _isRequesting = true;
    });

    try {
      await _apiClient.postJson(
        '/api/v1/teacher-requests',
        token: token,
        body: {
          'course': course.id,
          'tutor': course.tutorId,
          'message': 'Request to join course.',
        },
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent to teacher.')),
      );
    } on HttpException catch (err) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to send request.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRequesting = false;
        });
      }
    }
  }

  String _assetUrl(String? path) {
    if (path == null || path.isEmpty) {
      return '';
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final base = socketBaseUrl();
    if (path.startsWith('/')) {
      return '$base$path';
    }
    return '$base/$path';
  }

  Future<void> _openLessonMaterials(Lesson lesson) async {
    final imageUrl = _assetUrl(lesson.imageUrl);
    final pdfUrl = _assetUrl(lesson.pdfUrl);
    if (imageUrl.isEmpty && pdfUrl.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 12),
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              if (pdfUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(pdfUrl);
                    final launched = await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                    if (!launched && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unable to open PDF.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Open PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.buttonText,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final course = _course;
    if (course == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              const Text(
                'Course not found',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Header Section
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.headerPink,
                        AppColors.headerPink.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 50,
                        left: 24,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      if (course.isBestseller)
                        Positioned(
                          top: 100,
                          left: 24,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bestsellerYellow,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: const Text(
                              'BESTSELLER',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontFamily: 'Inter',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 40,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 24,
                        bottom: 60,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            size: 80,
                            color: AppColors.primary.withOpacity(0.4),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 24,
                        child: Row(
                          children: [
                            Icon(
                              Icons.send,
                              size: 16,
                              color: AppColors.textPrimary.withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 40,
                              height: 2,
                              decoration: BoxDecoration(
                                color: AppColors.textPrimary.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Content Section - Positioned to overlap
                Positioned(
                  top: 280,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                course.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            Text(
                              _formatPrice(course.price),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          course.id == '1' 
                            ? '6h 14min · ${course.lessonCount} Lessons'
                            : '${course.durationHours}h ${((course.durationHours * 60) % 60).toString().padLeft(2, '0')}min · ${course.lessonCount} Lessons',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'About this course',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          course.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.expand_more,
                              color: AppColors.textLight,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.redAccent,
                                fontFamily: 'Inter',
                              ),
                            ),
                          )
                        else if (_lessons.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'No lessons yet.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: 'Inter',
                              ),
                            ),
                          )
                        else
                          ..._lessons.map((lesson) {
                            return LessonListItem(
                              lesson: lesson,
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.coursePlayer,
                                  arguments: {
                                    'course': course,
                                    'lesson': lesson,
                                  },
                                );
                              },
                              onMaterialsTap: () => _openLessonMaterials(lesson),
                            );
                          }),
                        const SizedBox(height: 100), // Space for bottom bar
                      ],
                    ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.favoriteOrangeLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.favoriteOrange,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.star_outline,
                    color: AppColors.favoriteOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PrimaryButton(
                    text: HiveService.currentUserRole?.toLowerCase() == 'student'
                        ? (_isRequesting ? 'Sending...' : 'Request Teacher')
                        : 'Buy Now',
                    onPressed: HiveService.currentUserRole?.toLowerCase() ==
                            'student'
                        ? (_isRequesting ? null : () => _sendTeacherRequest(course))
                        : () {
                            final token = HiveService.authToken;
                            if (token == null || token.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please log in to purchase.'),
                                ),
                              );
                              Navigator.of(context).pushNamed(AppRoutes.login);
                              return;
                            }
                            if (course.id.isEmpty || course.price <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Course information is missing.'),
                                ),
                              );
                              return;
                            }
                            Navigator.of(context).pushNamed(
                              AppRoutes.paymentMethod,
                              arguments: {
                                'returnRoute': AppRoutes.courseDetail,
                                'returnArgs': course,
                                'courseId': course.id,
                                'amount': course.price,
                              },
                            );
                          },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

