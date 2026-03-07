import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/widgets/file_picker_screen.dart';
import '../../../../core/widgets/platform_file_image.dart';
import '../../../teacher_dashboard/presentation/widgets/teacher_bottom_nav.dart';

class TeacherCoursesPage extends StatefulWidget {
  const TeacherCoursesPage({Key? key}) : super(key: key);

  @override
  State<TeacherCoursesPage> createState() => _TeacherCoursesPageState();
}

class _TeacherCoursesPageState extends State<TeacherCoursesPage> {
  int _currentNavIndex = 1;
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  bool _isClearing = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _courses = [];

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    setState(fn);
  }

  void _onNavTap(int index) {
    if (index == _currentNavIndex) {
      return;
    }
    setState(() {
      _currentNavIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherHome);
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

  void _openCreateCourse() {
    Navigator.of(context)
        .pushNamed(AppRoutes.teacherCreateCourse)
        .then((_) => _loadCourses());
  }

  Future<bool> _isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any((item) => item != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  String _fileNameFromPath(String path) {
    final normalized = path.replaceAll('\\', '/');
    final name = normalized.split('/').last.trim();
    return name.isEmpty ? 'file' : name;
  }

  SelectedFile? _selectedFileFromDraft(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final data = Map<String, dynamic>.from(raw);
    final path = data['path']?.toString() ?? '';
    if (path.isEmpty) {
      return null;
    }
    final name = data['name']?.toString();
    return SelectedFile(
      name: (name == null || name.trim().isEmpty) ? _fileNameFromPath(path) : name,
      path: path,
      extension: data['extension']?.toString(),
      mimeType: data['mimeType']?.toString(),
    );
  }

  Future<http.MultipartFile> _buildMultipartFile(
    SelectedFile file,
    String fieldName,
  ) async {
    if (file.path != null && file.path!.isNotEmpty) {
      return http.MultipartFile.fromPath(fieldName, file.path!);
    }
    if (file.bytes != null) {
      return http.MultipartFile.fromBytes(
        fieldName,
        file.bytes!,
        filename: file.name,
      );
    }
    throw Exception('File data unavailable');
  }

  Future<void> _uploadCoursePdf({
    required String token,
    required String courseId,
    required SelectedFile file,
  }) async {
    final errors = <HttpException>[];

    Future<bool> tryUpload(Future<void> Function() run) async {
      try {
        await run();
        return true;
      } on HttpException catch (err) {
        errors.add(err);
        return false;
      }
    }

    if (await tryUpload(() async {
      final upload = await _buildMultipartFile(file, 'pdf');
      await _apiClient.postMultipart(
        '/api/v1/courses/$courseId/materials',
        token: token,
        fields: const {'type': 'pdf', 'title': 'Course PDF'},
        files: [upload],
      );
    })) {
      return;
    }

    if (await tryUpload(() async {
      final upload = await _buildMultipartFile(file, 'pdf');
      await _apiClient.postMultipart(
        '/api/v1/courses/$courseId/pdf',
        token: token,
        files: [upload],
      );
    })) {
      return;
    }

    throw (errors.isNotEmpty
        ? errors.first
        : Exception('Unable to upload PDF'));
  }

  Future<void> _syncOfflineCourses() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      return;
    }
    if (!await _isOnline()) {
      return;
    }

    final drafts = HiveService.getTeacherOfflineCourseDrafts();
    if (drafts.isEmpty) {
      return;
    }

    var synced = 0;
    for (final draft in drafts) {
      final localId = draft['localId']?.toString() ?? '';
      if (localId.isEmpty) {
        continue;
      }
      try {
        final response = await _apiClient.postJson(
          '/api/v1/courses',
          token: token,
          body: {
            'title': draft['title']?.toString() ?? '',
            'category': draft['category']?.toString() ?? '',
            'description': draft['description']?.toString() ?? '',
            'features': (draft['features'] is List)
                ? List<dynamic>.from(draft['features'] as List)
                : <dynamic>[],
            'price': (draft['price'] as num?)?.toDouble() ?? 0,
            'level': draft['level']?.toString() ?? 'Beginner',
            'lessonCount': (draft['lessonCount'] as num?)?.toInt() ?? 0,
            'durationHours': (draft['durationHours'] as num?)?.toInt() ?? 0,
            'instructorName':
                draft['instructorName']?.toString() ?? 'Instructor',
            'isNew': true,
            'scheduleDate': draft['scheduleDate']?.toString() ?? '',
            'scheduleTime': draft['scheduleTime']?.toString() ?? '',
          },
        );

        final data = response['data'];
        final courseId = data is Map<String, dynamic>
            ? (data['_id']?.toString() ?? data['id']?.toString() ?? '')
            : '';
        if (courseId.isEmpty) {
          throw Exception('Missing course id');
        }

        final imageFile = _selectedFileFromDraft(draft['courseImage']);
        if (imageFile != null) {
          final upload = await _buildMultipartFile(imageFile, 'image');
          await _apiClient.postMultipart(
            '/api/v1/courses/$courseId/image',
            token: token,
            files: [upload],
          );
        }

        final pdfFile = _selectedFileFromDraft(draft['coursePdf']);
        if (pdfFile == null) {
          throw Exception('Missing offline course PDF');
        }
        await _uploadCoursePdf(token: token, courseId: courseId, file: pdfFile);

        final lessonList = draft['lessons'];
        if (lessonList is List) {
          for (var i = 0; i < lessonList.length; i++) {
            final lessonRaw = lessonList[i];
            if (lessonRaw is! Map) {
              continue;
            }
            final lesson = Map<String, dynamic>.from(lessonRaw);
            final fileType = lesson['type']?.toString() ?? 'resource';
            final lessonResponse = await _apiClient.postJson(
              '/api/v1/courses/$courseId/lessons',
              token: token,
              body: {
                'title': lesson['title']?.toString() ?? 'Lesson ${i + 1}',
                'description': lesson['description']?.toString() ?? '',
                'durationMinutes': 0,
                'order': i + 1,
                'fileType': fileType,
              },
            );
            final lessonData = lessonResponse['data'];
            final lessonId = lessonData is Map<String, dynamic>
                ? (lessonData['_id']?.toString() ??
                    lessonData['id']?.toString() ??
                    '')
                : '';
            if (lessonId.isEmpty) {
              throw Exception('Missing lesson id');
            }
            final lessonFile = _selectedFileFromDraft(lesson['file']);
            if (lessonFile == null) {
              throw Exception('Missing lesson file');
            }
            final upload = await _buildMultipartFile(lessonFile, 'lessonFile');
            await _apiClient.postMultipart(
              '/api/v1/courses/$courseId/lessons/$lessonId/materials',
              token: token,
              fields: {
                'fileType': fileType,
                'type': fileType,
                if ((lesson['description']?.toString() ?? '').trim().isNotEmpty)
                  'description': lesson['description'].toString().trim(),
              },
              files: [upload],
            );
          }
        }

        await HiveService.removeTeacherOfflineCourseDraft(localId);
        synced++;
      } catch (_) {
        // Keep the draft for a future retry.
      }
    }

    if (synced > 0 && mounted) {
      _showSnack('$synced local course(s) synced to server.');
    }
  }

  List<Map<String, dynamic>> _localDraftCourses() {
    final drafts = HiveService.getTeacherOfflineCourseDrafts();
    return drafts.map((draft) {
      final features = draft['features'];
      final featuresLabel = features is List
          ? features.map((e) => e.toString()).join(', ')
          : '';
      final imagePath =
          draft['imageUrl']?.toString() ??
          (draft['courseImage'] is Map
              ? (draft['courseImage']['path']?.toString() ?? '')
              : '');
      return <String, dynamic>{
        'localId': draft['localId']?.toString() ?? '',
        '_id': '',
        'id': '',
        'title': draft['title']?.toString() ?? 'Untitled course',
        'description': draft['description']?.toString() ?? '',
        'category': draft['category']?.toString() ?? 'General',
        'level': draft['category']?.toString() ?? 'General',
        'difficulty': draft['level']?.toString() ?? 'Beginner',
        'mentor': draft['instructorName']?.toString() ?? 'Instructor',
        'instructorName': draft['instructorName']?.toString() ?? 'Instructor',
        'weeks': '0 hours',
        'students': '0 students',
        'rating': '0.0',
        'status': 'Pending Sync',
        'schedule': 'Local draft',
        'features': featuresLabel,
        'price': draft['price'],
        'lessonCount': draft['lessonCount'],
        'imageUrl': imagePath,
        'coursePdfPath': (draft['coursePdfPath']?.toString() ??
                (draft['coursePdf'] is Map
                    ? (draft['coursePdf']['path']?.toString() ?? '')
                    : ''))
            .toString(),
        'isLocalOnly': true,
      };
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    _setStateIfMounted(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _syncOfflineCourses();
    final localCourses = _localDraftCourses();

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
        final mapped = data.map<Map<String, dynamic>>((item) {
          final course =
              item is Map<String, dynamic> ? item : <String, dynamic>{};
          final duration = course['durationHours'];
          final durationLabel =
              duration is num ? '${duration.toInt()} hours' : '0 hours';
          final scheduleDate = course['scheduleDate']?.toString();
          final scheduleTime = course['scheduleTime']?.toString();
          final scheduleParts = <String>[];
          if (scheduleDate != null && scheduleDate.isNotEmpty) {
            scheduleParts.add(scheduleDate);
          }
          if (scheduleTime != null && scheduleTime.isNotEmpty) {
            scheduleParts.add(scheduleTime);
          }
          final scheduleLabel = scheduleParts.isNotEmpty
              ? scheduleParts.join(' ')
              : 'Schedule TBD';
          final featuresValue = course['features'];
          String featuresLabel = '';
          if (featuresValue is List) {
            featuresLabel = featuresValue.map((e) => e.toString()).join(', ');
          } else if (featuresValue is String) {
            featuresLabel = featuresValue;
          }
          final approvalStatus =
              course['approvalStatus']?.toString().toLowerCase() ?? '';
          final isPublished = course['isPublished'] == true;
          final statusLabel = approvalStatus == 'approved' && isPublished
              ? 'Approved'
              : approvalStatus == 'rejected'
                  ? 'Rejected'
                  : 'Pending Admin';
           return {
            '_id': course['_id']?.toString() ?? course['id']?.toString() ?? '',
            'id': course['_id']?.toString() ?? course['id']?.toString() ?? '',
            'title': course['title']?.toString() ?? 'Untitled course',
            'description': course['description']?.toString() ?? '',
            'category': course['category']?.toString() ?? 'General',
            'level': course['category']?.toString() ?? 'General',
            'difficulty': course['level']?.toString() ?? 'Beginner',
            'mentor':
                course['instructorName']?.toString() ?? 'Unknown instructor',
            'instructorName':
                course['instructorName']?.toString() ?? 'Unknown instructor',
            'weeks': durationLabel,
            'students': '0 students',
            'rating': '0.0',
            'status': statusLabel,
            'schedule': scheduleLabel,
            'features': featuresLabel,
             'price': course['price'],
             'lessonCount': course['lessonCount'],
             'imageUrl': course['imageUrl']?.toString() ??
                 course['image']?.toString() ??
                 '',
             'coursePdfPath': course['coursePdfPath']?.toString() ??
                 course['pdfUrl']?.toString() ??
                 course['pdf']?.toString() ??
                 course['coursePdfUrl']?.toString() ??
                 course['coursePdf']?.toString() ??
                 '',
           };
         }).toList();
        _setStateIfMounted(() {
          _courses = [...localCourses, ...mapped];
        });
      } else {
        _setStateIfMounted(() {
          _courses = localCourses;
          _errorMessage = localCourses.isEmpty
              ? 'Unexpected response format.'
              : null;
        });
      }
    } on HttpException catch (err) {
      _setStateIfMounted(() {
        _courses = localCourses;
        _errorMessage = localCourses.isEmpty ? err.message : null;
      });
    } catch (_) {
      _setStateIfMounted(() {
        _courses = localCourses;
        _errorMessage = localCourses.isEmpty
            ? 'Unable to load courses. Please try again.'
            : null;
      });
    } finally {
      _setStateIfMounted(() {
        _isLoading = false;
      });
    }
  }

  String _courseIdFrom(Map<String, dynamic> course) {
    return course['_id']?.toString() ?? course['id']?.toString() ?? '';
  }

  Future<bool> _deleteCourseOnServer(String courseId) async {
    final token = HiveService.authToken;
    final deletePaths = <String>[
      '/api/v1/courses/$courseId',
      '/api/v1/courses/$courseId/delete',
    ];

    HttpException? lastError;
    for (final path in deletePaths) {
      try {
        await _apiClient.deleteJson(path, token: token);
        return true;
      } on HttpException catch (err) {
        lastError = err;
        if (err.statusCode == 404 || err.statusCode == 405) {
          continue;
        }
        break;
      } catch (_) {
        break;
      }
    }

    if (lastError != null) {
      throw lastError;
    }
    throw HttpException(500, 'Unable to delete course.');
  }

  Future<void> _deleteCourse(Map<String, dynamic> course) async {
    final localId = course['localId']?.toString() ?? '';
    if (localId.isNotEmpty || course['isLocalOnly'] == true) {
      final shouldDeleteLocal = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Delete local course'),
            content: const Text('This removes the local draft before sync.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          );
        },
      );
      if (shouldDeleteLocal != true || !mounted) {
        return;
      }
      await HiveService.removeTeacherOfflineCourseDraft(localId);
      await _loadCourses();
      _showSnack('Local draft deleted.');
      return;
    }

    final courseId = _courseIdFrom(course);
    if (courseId.isEmpty) {
      _showSnack('Missing course id.');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete course'),
          content: const Text('This will remove this course from server.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
    if (shouldDelete != true || !mounted) {
      return;
    }

    _setStateIfMounted(() {
      _isLoading = true;
    });

    try {
      await _deleteCourseOnServer(courseId);
      await _loadCourses();
      _showSnack('Course deleted.');
    } on HttpException catch (err) {
      _showSnack(err.message);
    } catch (_) {
      _showSnack('Unable to delete course.');
    } finally {
      _setStateIfMounted(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearPage() async {
    if (_courses.isEmpty) {
      _showSnack('No courses to clear.');
      return;
    }

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear page'),
          content: const Text(
            'Delete all shown courses from server and clear this page?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Clear all',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );
    if (shouldClear != true || !mounted) {
      return;
    }

    _setStateIfMounted(() {
      _isClearing = true;
    });

    var deletedCount = 0;
    var failedCount = 0;
    final snapshot = List<Map<String, dynamic>>.from(_courses);
    for (final course in snapshot) {
      final localId = course['localId']?.toString() ?? '';
      if (localId.isNotEmpty || course['isLocalOnly'] == true) {
        try {
          await HiveService.removeTeacherOfflineCourseDraft(localId);
          deletedCount++;
        } catch (_) {
          failedCount++;
        }
        continue;
      }
      final courseId = _courseIdFrom(course);
      if (courseId.isEmpty) {
        failedCount++;
        continue;
      }
      try {
        final deleted = await _deleteCourseOnServer(courseId);
        if (deleted) {
          deletedCount++;
        } else {
          failedCount++;
        }
      } catch (_) {
        failedCount++;
      }
    }

    await _loadCourses();
    _setStateIfMounted(() {
      _isClearing = false;
    });
    _showSnack('Deleted: $deletedCount, Failed: $failedCount');
  }

  @override
  Widget build(BuildContext context) {
    final courses = _courses.isNotEmpty
        ? _courses
        : List<Map<String, dynamic>>.generate(0, (_) => {});

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.teacherHome,
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.teacherBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.teacherPrimaryDark),
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.teacherHome,
              (route) => false,
            ),
          ),
          title: const Text(
            'My Courses',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.teacherPrimaryDark,
              fontFamily: 'OpenSans',
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.teacherPrimary),
              onPressed: _openCreateCourse,
            ),
            TextButton(
              onPressed: _isClearing || _isLoading ? null : _clearPage,
              child: Text(
                _isClearing ? 'Clearing...' : 'Clear page',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.teacherPrimary,
                  fontFamily: 'OpenSans',
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  PrimaryButton(
                    text: 'Create course',
                    height: 44,
                    onPressed: _openCreateCourse,
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
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
                  ...courses.map(
                    (course) => GestureDetector(
                      onTap: () {
                        Navigator.of(context)
                            .pushNamed(
                              AppRoutes.teacherCourseDetail,
                              arguments: course,
                            )
                            .then((_) => _loadCourses());
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.teacherSurface,
                          borderRadius: BorderRadius.circular(16),
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
                            _CourseImage(
                              imageUrl: _resolveAssetUrl(
                                course['imageUrl']?.toString(),
                              ),
                              pdfUrl: _resolveAssetUrl(
                                course['coursePdfPath']?.toString() ??
                                    course['pdfUrl']?.toString() ??
                                    course['pdf']?.toString(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course['title']?.toString() ??
                                        'Untitled course',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${course['level'] ?? 'General'} - ${course['mentor'] ?? 'Unknown instructor'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.teacherMuted,
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${course['students'] ?? '0 students'} - ${course['rating'] ?? '0.0'} rating - ${course['weeks'] ?? '0 hours'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.teacherMuted,
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    course['schedule']?.toString() ??
                                        'Schedule TBD',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.teacherMuted,
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                  if ((course['features'] ?? '')
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      course['features'].toString(),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.teacherMuted,
                                        fontFamily: 'OpenSans',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (course['status']?.toString() ==
                                                  'Approved')
                                          ? const Color(0xFFE8F8EE)
                                          : (course['status']?.toString() ==
                                                  'Rejected')
                                              ? const Color(0xFFFFEBEE)
                                              : const Color(0xFFFFF4E5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      course['status']?.toString() ?? 'Active',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.teacherPrimaryDark,
                                        fontFamily: 'OpenSans',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    tooltip: 'Delete course',
                                    onPressed: _isLoading || _isClearing
                                        ? null
                                        : () => _deleteCourse(course),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
      ),
    );
  }
}

String _resolveAssetUrl(String? raw) {
  if (raw == null) {
    return '';
  }
  var value = raw.trim();
  if (value.isEmpty) {
    return '';
  }
  if (_isLocalFilePath(value)) {
    return value;
  }
  value = value.replaceAll('\\', '/');
  if (value.startsWith('/api/v1/uploads/') ||
      value.startsWith('/api/v1/public/') ||
      value.startsWith('/api/v1/static/') ||
      value.startsWith('/api/v1/files/') ||
      value.startsWith('/api/v1/media/')) {
    value = value.substring('/api/v1'.length);
  } else if (value.startsWith('api/v1/uploads/') ||
      value.startsWith('api/v1/public/') ||
      value.startsWith('api/v1/static/') ||
      value.startsWith('api/v1/files/') ||
      value.startsWith('api/v1/media/')) {
    value = value.substring('api/v1'.length);
  }
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  final base = socketBaseUrl();
  if (value.startsWith('/')) {
    return '$base$value';
  }
  return '$base/$value';
}

bool _isLocalFilePath(String value) {
  final lower = value.toLowerCase();
  return value.startsWith('/') ||
      lower.startsWith('file://') ||
      lower.contains(':\\') ||
      lower.startsWith(r'\\');
}

class _CourseImage extends StatelessWidget {
  const _CourseImage({required this.imageUrl, required this.pdfUrl});

  final String imageUrl;
  final String pdfUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.teacherChip,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          pdfUrl.isNotEmpty ? Icons.picture_as_pdf_outlined : Icons.play_lesson,
          color: AppColors.teacherPrimaryDark,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: _isLocalFilePath(imageUrl)
          ? (kIsWeb
              ? Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.teacherChip,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.image_outlined,
                      color: AppColors.teacherMuted),
                )
              : platformFileImage(
                  imageUrl.replaceFirst('file://', ''),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.teacherChip,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.broken_image_outlined,
                        color: AppColors.teacherMuted),
                  ),
                ))
          : Image.network(
              imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.teacherChip,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.broken_image_outlined,
                    color: AppColors.teacherMuted),
              ),
            ),
    );
  }
}

