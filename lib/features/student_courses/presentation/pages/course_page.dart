import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../domain/entities/course.dart';
import '../providers/student_courses_provider.dart';
import '../widgets/course_list_item.dart';
import '../widgets/filter_sheet.dart';
import '../../../student_dashboard/presentation/widgets/bottom_nav.dart';

class CoursePage extends ConsumerStatefulWidget {
  const CoursePage({Key? key}) : super(key: key);

  @override
  ConsumerState<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends ConsumerState<CoursePage> {
  int _currentNavIndex = 1;
  String _selectedSort = 'Newest';
  String _selectedCategory = 'All';
  String _selectedLevel = 'All';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  String _searchQuery = '';

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

  List<Course> _filteredCourses(List<Course> courses) {
    final minPrice = double.tryParse(_minPriceController.text.trim()) ?? 0;
    final maxPrice = double.tryParse(_maxPriceController.text.trim());
    final query = _searchQuery.trim().toLowerCase();
    final filtered = courses.where((course) {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(courseCatalogViewModelProvider.notifier).loadInitialData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final catalogState = ref.watch(courseCatalogViewModelProvider);
    final filteredCourses = _filteredCourses(catalogState.courses);
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
                  '${catalogState.courses.length} courses',
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
                          ref
                              .read(courseCatalogViewModelProvider.notifier)
                              .refreshCourses(searchQuery: _searchQuery);
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
                              ...catalogState.courses
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
            if (catalogState.isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (catalogState.errorMessage != null)
              Expanded(
                child: Center(
                  child: Text(
                    catalogState.errorMessage!,
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
                  children: filteredCourses.map((course) {
                    return CourseListItem(
                      course: course,
                      showOpenButton: true,
                      isFavorite:
                          catalogState.favoriteCourseIds.contains(course.id),
                      onFavoriteTap: () {
                        ref
                            .read(courseCatalogViewModelProvider.notifier)
                            .toggleFavorite(course);
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

