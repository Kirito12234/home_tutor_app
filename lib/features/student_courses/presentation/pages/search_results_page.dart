import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../domain/entities/course.dart';
import '../widgets/course_list_item.dart';
import '../widgets/filter_sheet.dart';
import '../../../student_dashboard/domain/entities/lesson.dart';
import '../../../student_dashboard/presentation/widgets/bottom_nav.dart';

class SearchResultsPage extends StatefulWidget {
  final String? query;

  const SearchResultsPage({Key? key, this.query}) : super(key: key);

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ApiClient _apiClient = ApiClient();
  final List<Course> _allCourses = <Course>[];
  List<Course> _courses = <Course>[];
  int _currentNavIndex = 2;
  bool _isLoading = false;
  String? _errorMessage;
  final Set<String> _favoriteCourseIds = <String>{};

  List<String> _selectedCategories = <String>[];
  String? _selectedDuration;
  RangeValues _priceRange = const RangeValues(0, 100000);
  List<String> _filterChips = <String>[];
  String _activeChip = 'All';

  bool get _isStudent => HiveService.currentUserRole?.toLowerCase() == 'student';

  void _onNavTap(int index) {
    setState(() {
      _currentNavIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.courses);
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
  void initState() {
    super.initState();
    _searchController.text = widget.query ?? '';
    _loadCourses();
  }

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    setState(fn);
  }

  Future<void> _loadCourses() async {
    _setStateIfMounted(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final params = <String>[];
      if (_isStudent) {
        params.add('status=approved');
      }
      if (_searchController.text.trim().isNotEmpty) {
        params.add('search=${Uri.encodeComponent(_searchController.text.trim())}');
      }
      final query = params.isEmpty ? '' : '?${params.join('&')}';
      final response = await _apiClient.getJson(
        '/api/v1/courses$query',
        token: HiveService.authToken,
      );
      final data = response['data'];
      if (data is! List) {
        throw Exception('Unexpected response format');
      }
      final mapped = data
          .whereType<Map<String, dynamic>>()
          .where(_isCourseApprovedForStudent)
          .map(_mapCourse)
          .toList();
      final categories = mapped
          .map((e) => e.category)
          .where((e) => e.trim().isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      _setStateIfMounted(() {
        _allCourses
          ..clear()
          ..addAll(mapped);
        _filterChips = categories;
      });
      _applyFilters();
    } on HttpException catch (err) {
      _setStateIfMounted(() {
        _errorMessage = err.message;
        _allCourses.clear();
        _courses = <Course>[];
      });
    } catch (_) {
      _setStateIfMounted(() {
        _errorMessage = 'Unable to load courses.';
        _allCourses.clear();
        _courses = <Course>[];
      });
    } finally {
      _setStateIfMounted(() {
        _isLoading = false;
      });
    }
  }

  bool _isCourseApprovedForStudent(Map<String, dynamic> course) {
    if (!_isStudent) {
      return true;
    }
    final explicitApproved =
        course['isApproved'] == true || course['approved'] == true;
    final approvalStatus =
        course['approvalStatus']?.toString().toLowerCase() ?? '';
    final status = course['status']?.toString().toLowerCase() ?? '';

    if (approvalStatus == 'rejected' ||
        approvalStatus == 'pending' ||
        approvalStatus == 'draft' ||
        status == 'rejected' ||
        status == 'pending' ||
        status == 'draft') {
      return false;
    }

    return explicitApproved ||
        approvalStatus == 'approved' ||
        status == 'approved';
  }

  Course _mapCourse(Map<String, dynamic> course) {
    final tutor = course['tutor'];
    final tutorName =
        tutor is Map<String, dynamic> ? tutor['name']?.toString() : null;
    final tutorId = tutor is Map<String, dynamic> ? tutor['_id']?.toString() : null;
    return Course(
      id: course['_id']?.toString() ?? course['id']?.toString() ?? 'course',
      title: course['title']?.toString() ?? 'Course',
      instructor: course['instructorName']?.toString() ?? tutorName ?? 'Instructor',
      tutorId: tutorId,
      price: (course['price'] as num?)?.toDouble() ?? 0,
      durationHours: (course['durationHours'] as num?)?.toInt() ?? 0,
      lessonCount: (course['lessonCount'] as num?)?.toInt() ?? 0,
      category: course['category']?.toString() ?? 'General',
      imageUrl: course['imageUrl']?.toString(),
      description: course['description']?.toString() ?? '',
      isBestseller: course['isBestseller'] == true,
      isPopular: course['isPopular'] == true,
      isNew: course['isNew'] == true,
      lessons: const <Lesson>[],
    );
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    _setStateIfMounted(() {
      _courses = _allCourses.where((course) {
        if (query.isNotEmpty && !course.title.toLowerCase().contains(query)) {
          return false;
        }
        if (_activeChip != 'All' && course.category != _activeChip) {
          return false;
        }
        if (_selectedCategories.isNotEmpty &&
            !_selectedCategories.contains(course.category)) {
          return false;
        }
        if (course.price < _priceRange.start || course.price > _priceRange.end) {
          return false;
        }
        if (_selectedDuration != null && _selectedDuration!.trim().isNotEmpty) {
          final duration = course.durationHours;
          switch (_selectedDuration) {
            case '<2h':
              if (duration >= 2) return false;
              break;
            case '2-5h':
              if (duration < 2 || duration > 5) return false;
              break;
            case '>5h':
              if (duration <= 5) return false;
              break;
          }
        }
        return true;
      }).toList();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        selectedCategories: _selectedCategories,
        selectedDuration: _selectedDuration,
        priceRange: _priceRange,
        onApply: (categories, duration, priceRange) {
          setState(() {
            _selectedCategories = categories;
            _selectedDuration = duration;
            _priceRange = priceRange ?? const RangeValues(0, 100000);
          });
          _applyFilters();
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
                onSubmitted: (_) => _loadCourses(),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontFamily: 'OpenSans',
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          color: AppColors.textSecondary,
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                            _loadCourses();
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.tune),
                        color: AppColors.textSecondary,
                        onPressed: _showFilterSheet,
                      ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_filterChips.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: ['All', ..._filterChips].map((chip) {
                  final isSelected = _activeChip == chip;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _activeChip = chip;
                        });
                        _applyFilters();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          chip,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected
                                ? AppColors.buttonText
                                : AppColors.textSecondary,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Results',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  fontFamily: 'OpenSans',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.redAccent,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _loadCourses,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (_courses.isEmpty) {
                  return const Center(
                    child: Text(
                      'No approved courses found.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontFamily: 'OpenSans',
                      ),
                    ),
                  );
                }
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: _courses.map((course) {
                      return CourseListItem(
                        course: course,
                        isFavorite: _favoriteCourseIds.contains(course.id),
                        onFavoriteTap: () {
                          setState(() {
                            if (_favoriteCourseIds.contains(course.id)) {
                              _favoriteCourseIds.remove(course.id);
                            } else {
                              _favoriteCourseIds.add(course.id);
                            }
                          });
                        },
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.courseDetail,
                            arguments: course,
                          );
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          BottomNav(
            currentIndex: _currentNavIndex,
            onTap: _onNavTap,
          ),
        ],
      ),
    );
  }
}


