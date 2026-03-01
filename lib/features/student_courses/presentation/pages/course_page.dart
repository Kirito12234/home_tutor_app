import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../domain/entities/course.dart';
import '../widgets/course_list_item.dart';
import '../widgets/filter_sheet.dart';
import '../../../student_dashboard/presentation/widgets/bottom_nav.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({Key? key}) : super(key: key);

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  int _currentNavIndex = 1;
  String _selectedSort = 'Newest';
  String _selectedCategory = 'All';
  String _selectedLevel = 'All';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  String _searchQuery = '';
  final ApiClient _apiClient = ApiClient();
  final List<Course> _courses = [];
  final Set<String> _favoriteCourseIds = <String>{};
  bool _isLoading = false;
  String? _errorMessage;
  bool get _isStudent =>
      HiveService.currentUserRole?.toLowerCase() == 'student';

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    setState(fn);
  }

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
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.searchResults,
            arguments: null,
          );
        },
      ),
    );
  }

  List<Course> get _filteredCourses {
    final minPrice = double.tryParse(_minPriceController.text.trim()) ?? 0;
    final maxPrice = double.tryParse(_maxPriceController.text.trim());
    final query = _searchQuery.trim().toLowerCase();
    final filtered = _courses.where((course) {
      if (_selectedCategory != 'All' && course.category != _selectedCategory) {
        return false;
      }
      if (query.isNotEmpty &&
          !course.title.toLowerCase().contains(query) &&
          !course.instructor.toLowerCase().contains(query)) {
        return false;
      }
      if (course.price < minPrice) {
        return false;
      }
      if (maxPrice != null && maxPrice > 0 && course.price > maxPrice) {
        return false;
      }
      return true;
    }).toList();

    switch (_selectedSort) {
      case 'Price Low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price High':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'A-Z':
        filtered.sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'Newest':
      default:
        filtered.sort((a, b) {
          if (a.isNew == b.isNew) {
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          }
          return a.isNew ? -1 : 1;
        });
    }
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait<void>([
      _loadCourses(),
      _loadFavoriteCourseIds(),
    ]);
  }

  Future<void> _loadFavoriteCourseIds() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      return;
    }
    final paths = <String>[
      '/api/v1/users/me/favorites',
      '/api/users/me/favorites',
      '/api/v1/favorites',
    ];
    for (final path in paths) {
      try {
        final response = await _apiClient.getJson(path, token: token);
        final data = response['data'];
        final ids = <String>{};
        if (data is Map<String, dynamic>) {
          final courses = data['courses'];
          if (courses is List) {
            for (final course in courses.whereType<Map<String, dynamic>>()) {
              final id =
                  course['_id']?.toString() ?? course['id']?.toString() ?? '';
              if (id.isNotEmpty) {
                ids.add(id);
              }
            }
          }
        } else if (data is List) {
          for (final row in data.whereType<Map<String, dynamic>>()) {
            final course = row['course'];
            final map =
                course is Map<String, dynamic> ? course : <String, dynamic>{};
            final id = map['_id']?.toString() ??
                map['id']?.toString() ??
                row['_id']?.toString() ??
                row['id']?.toString() ??
                '';
            if (id.isNotEmpty) {
              ids.add(id);
            }
          }
        }
        _setStateIfMounted(() {
          _favoriteCourseIds
            ..clear()
            ..addAll(ids);
        });
        return;
      } on HttpException catch (err) {
        if (err.statusCode == 404 || err.statusCode == 405) {
          continue;
        }
        return;
      } catch (_) {
        return;
      }
    }
  }

  Future<void> _toggleFavoriteCourse(Course course) async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      return;
    }
    final isFavorite = _favoriteCourseIds.contains(course.id);
    _setStateIfMounted(() {
      if (isFavorite) {
        _favoriteCourseIds.remove(course.id);
      } else {
        _favoriteCourseIds.add(course.id);
      }
    });

    try {
      if (isFavorite) {
        final paths = <String>[
          '/api/v1/users/me/favorites/courses/${course.id}',
          '/api/users/me/favorites/courses/${course.id}',
          '/api/v1/favorites/${course.id}',
        ];
        var success = false;
        for (final path in paths) {
          try {
            await _apiClient.deleteJson(path, token: token);
            success = true;
            break;
          } on HttpException catch (err) {
            if (err.statusCode == 404 || err.statusCode == 405) {
              continue;
            }
            rethrow;
          }
        }
        if (!success) {
          throw Exception('Unable to remove favorite');
        }
      } else {
        final paths = <String>[
          '/api/v1/users/me/favorites/courses/${course.id}',
          '/api/users/me/favorites/courses/${course.id}',
          '/api/v1/favorites',
        ];
        var success = false;
        for (final path in paths) {
          try {
            if (path.endsWith('/favorites')) {
              await _apiClient.postJson(
                path,
                token: token,
                body: {'courseId': course.id},
              );
            } else {
              await _apiClient.postJson(path, token: token, body: const {});
            }
            success = true;
            break;
          } on HttpException catch (err) {
            if (err.statusCode == 404 || err.statusCode == 405) {
              continue;
            }
            rethrow;
          }
        }
        if (!success) {
          throw Exception('Unable to add favorite');
        }
      }
    } catch (_) {
      _setStateIfMounted(() {
        if (isFavorite) {
          _favoriteCourseIds.add(course.id);
        } else {
          _favoriteCourseIds.remove(course.id);
        }
      });
    }
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
        _setStateIfMounted(() {
          _courses
            ..clear()
            ..addAll(mapped);
        });
      } else {
        _setStateIfMounted(() {
          _errorMessage = 'Unexpected response format.';
          _courses.clear();
        });
      }
    } on HttpException catch (err) {
      _setStateIfMounted(() {
        _errorMessage = err.message;
        _courses.clear();
      });
    } catch (_) {
      _setStateIfMounted(() {
        _errorMessage = 'Unable to load courses.';
        _courses.clear();
      });
    } finally {
      _setStateIfMounted(() {
        _isLoading = false;
      });
    }
  }

  Course _mapCourse(Map<String, dynamic> course) {
    final tutor = course['tutor'];
    final tutorName =
        tutor is Map<String, dynamic> ? tutor['name']?.toString() : null;
    final tutorId =
        tutor is Map<String, dynamic> ? tutor['_id']?.toString() : null;
    return Course(
      id: course['_id']?.toString() ?? course['id']?.toString() ?? 'course',
      title: course['title']?.toString() ?? 'Course',
      instructor:
          course['instructorName']?.toString() ?? tutorName ?? 'Instructor',
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
    final media = MediaQuery.of(context);
    return WillPopScope(
      onWillPop: _handleBack,
      child: MediaQuery(
        data: media.copyWith(textScaler: const TextScaler.linear(1.0)),
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Course',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary,
              fontFamily: 'OpenSans',
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 24),
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.backgroundLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                (HiveService.currentUserName ?? 'S')
                    .trim()
                    .toUpperCase()
                    .padRight(2, 'H')
                    .substring(0, 2),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'OpenSans',
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_courses.length} courses',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        onSubmitted: (value) {
                          setState(() {
                            _searchQuery = value.trim();
                          });
                          _loadCourses();
                        },
                        decoration: InputDecoration(
                          hintText: 'Search course',
                          hintStyle: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            fontFamily: 'OpenSans',
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: const Icon(Icons.search,
                              color: AppColors.textSecondary),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.tune,
                                color: AppColors.textSecondary),
                            onPressed: _showFilterSheet,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            value: _selectedCategory,
                            items: <String>[
                              'All',
                              ..._courses
                                  .map((e) => e.category)
                                  .toSet()
                                  .toList()
                                ..sort(),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value ?? 'All';
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildDropdown(
                            value: _selectedLevel,
                            items: const ['All', 'Beginner'],
                            onChanged: (value) {
                              setState(() {
                                _selectedLevel = value ?? 'All';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 390) {
                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildPriceField(
                                      controller: _minPriceController,
                                      hint: 'Min price',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildPriceField(
                                      controller: _maxPriceController,
                                      hint: 'Max price',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              _buildDropdown(
                                value: _selectedSort,
                                items: const [
                                  'Newest',
                                  'Price Low',
                                  'Price High',
                                  'A-Z'
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSort = value ?? 'Newest';
                                  });
                                },
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(
                              child: _buildPriceField(
                                controller: _minPriceController,
                                hint: 'Min price',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildPriceField(
                                controller: _maxPriceController,
                                hint: 'Max price',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildDropdown(
                                value: _selectedSort,
                                items: const [
                                  'Newest',
                                  'Price Low',
                                  'Price High',
                                  'A-Z'
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSort = value ?? 'Newest';
                                  });
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
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
                      fontFamily: 'OpenSans',
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: _filteredCourses.map((course) {
                    return CourseListItem(
                      course: course,
                      showOpenButton: true,
                      isFavorite: _favoriteCourseIds.contains(course.id),
                      onFavoriteTap: () {
                        _toggleFavoriteCourse(course);
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
              ),
            BottomNav(
              currentIndex: _currentNavIndex,
              onTap: (index) {
                if (index == _currentNavIndex) {
                  return;
                }
                setState(() {
                  _currentNavIndex = index;
                });
                switch (index) {
                  case 0:
                    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                    break;
                  case 2:
                    Navigator.of(context)
                        .pushReplacementNamed(AppRoutes.searchResults);
                    break;
                  case 3:
                    Navigator.of(context)
                        .pushReplacementNamed(AppRoutes.notifications);
                    break;
                  case 4:
                    Navigator.of(context)
                        .pushReplacementNamed(AppRoutes.account);
                    break;
                }
              },
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildPriceField({
    required TextEditingController controller,
    required String hint,
  }) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontFamily: 'OpenSans',
          ),
          filled: true,
          fillColor: AppColors.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    return SizedBox(
      height: 44,
      child: DropdownButtonFormField<String>(
        value: safeValue,
        onChanged: onChanged,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.background,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
        ),
        items: items
            .map(
              (e) => DropdownMenuItem<String>(
                value: e,
                child: Text(
                  e,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

