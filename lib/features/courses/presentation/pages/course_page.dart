import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/api/api_client.dart';
import '../../domain/entities/course.dart';
import '../widgets/course_category_card.dart';
import '../widgets/course_list_item.dart';
import '../widgets/filter_sheet.dart';
import '../../../dashboard/presentation/widgets/bottom_nav.dart';
import '../../data/dummy/dummy_courses.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({Key? key}) : super(key: key);

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  int _currentNavIndex = 1;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ApiClient _apiClient = ApiClient();
  final List<Course> _courses = [];
  bool _isLoading = false;
  String? _errorMessage;

  Future<bool> _handleBack() async {
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    return false;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        selectedCategories: [],
        onApply: (categories, duration, priceRange) {
          // Navigate to search results with filters
          Navigator.of(context).pushNamed(
            AppRoutes.searchResults,
            arguments: null,
          );
        },
      ),
    );
  }

  List<Course> get _filteredCourses {
    switch (_selectedFilter) {
      case 'Popular':
        return _courses.where((c) => c.isPopular).toList();
      case 'New':
        return _courses.where((c) => c.isNew).toList();
      default:
        return _courses;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final params = <String>[];
      if (_selectedFilter == 'Popular') {
        params.add('isPopular=true');
      } else if (_selectedFilter == 'New') {
        params.add('isNew=true');
      }
      if (_searchQuery.isNotEmpty) {
        params.add('search=${Uri.encodeComponent(_searchQuery)}');
      }
      final query = params.isEmpty ? '' : '?${params.join('&')}';
      final response = await _apiClient.getJson('/api/v1/courses$query');
      final data = response['data'];
      if (data is List) {
        final mapped = data
            .whereType<Map<String, dynamic>>()
            .map(_mapCourse)
            .toList();
        if (mapped.isNotEmpty) {
          setState(() {
            _courses
              ..clear()
              ..addAll(mapped);
          });
        } else {
          setState(() {
            _courses
              ..clear()
              ..addAll(DummyCourses.getCourses());
          });
        }
      } else {
        setState(() {
          _courses
            ..clear()
            ..addAll(DummyCourses.getCourses());
        });
      }
    } on HttpException catch (err) {
      setState(() {
        _errorMessage = null;
        _courses
          ..clear()
          ..addAll(DummyCourses.getCourses());
      });
    } catch (_) {
      setState(() {
        _errorMessage = null;
        _courses
          ..clear()
          ..addAll(DummyCourses.getCourses());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
      lessons: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Course',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 24),
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: AppColors.buttonText,
                size: 20,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: (value) {
                          setState(() {
                            _searchQuery = value.trim();
                          });
                          _loadCourses();
                        },
                        decoration: InputDecoration(
                          hintText: 'Find Cousre',
                          hintStyle: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            fontFamily: 'Inter',
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.tune,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: _showFilterSheet,
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
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  CourseCategoryCard(
                    title: 'Languege',
                    backgroundColor: AppColors.categoryBlue,
                    tagColor: AppColors.background,
                  ),
                  CourseCategoryCard(
                    title: 'Music',
                    backgroundColor: AppColors.categoryBeige,
                    tagColor: AppColors.categoryPurple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choice your course',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildFilterButton('All', _selectedFilter == 'All'),
                      const SizedBox(width: 12),
                      _buildFilterButton('Poular', _selectedFilter == 'Popular'),
                      const SizedBox(width: 12),
                      _buildFilterButton('New', _selectedFilter == 'New'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.redAccent,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: _filteredCourses.map((course) {
                    return CourseListItem(
                      course: course,
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.courseDetail,
                          arguments: course,
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            BottomNav(
              currentIndex: _currentNavIndex,
              onTap: (index) {
                setState(() {
                  _currentNavIndex = index;
                });
                switch (index) {
                  case 0:
                    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
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
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label == 'Poular' ? 'Popular' : label;
        });
        _loadCourses();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.inputBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.buttonText : AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

