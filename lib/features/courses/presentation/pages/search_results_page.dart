import 'package:flutter/material.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../data/dummy/dummy_courses.dart';
import '../../domain/entities/course.dart';
import '../widgets/course_list_item.dart';
import '../widgets/filter_sheet.dart';
import '../../../dashboard/presentation/widgets/bottom_nav.dart';

class SearchResultsPage extends StatefulWidget {
  final String? query;

  const SearchResultsPage({Key? key, this.query}) : super(key: key);

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Course> _courses = [];
  int _currentNavIndex = 2;
  List<String> _selectedCategories = [];
  String? _selectedDuration;
  RangeValues _priceRange = const RangeValues(0, 100000);
  final List<String> _filterChips = [
    'Visual identity',
    'Painting',
    'Coding',
    'Writing',
  ];

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

  void _loadCourses() {
    setState(() {
      _courses = DummyCourses.filterCourses(
        categories: _selectedCategories.isEmpty ? null : _selectedCategories,
        durationRange: _selectedDuration,
        minPrice: _priceRange.start,
        maxPrice: _priceRange.end,
      )
          .where((c) => c.title.toLowerCase().contains(
                _searchController.text.toLowerCase(),
              ))
          .toList();
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
          _loadCourses();
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
              child: StatefulBuilder(
                builder: (context, setState) {
                  return TextField(
                    controller: _searchController,
                    onChanged: (_) {
                      setState(() {});
                      _loadCourses();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
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
                                setState(() {});
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
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: _filterChips.map((chip) {
                final isSelected = _selectedCategories.contains(chip);
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedCategories.remove(chip);
                        } else {
                          _selectedCategories.add(chip);
                        }
                      });
                      _loadCourses();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        chip,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected
                              ? AppColors.buttonText
                              : AppColors.textSecondary,
                          fontFamily: 'Inter',
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
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: _courses.map((course) {
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
            onTap: _onNavTap,
          ),
        ],
      ),
    );
  }
}

