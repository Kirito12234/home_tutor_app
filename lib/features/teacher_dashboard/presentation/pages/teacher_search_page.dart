import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../widgets/teacher_bottom_nav.dart';

class TeacherSearchPage extends StatefulWidget {
  const TeacherSearchPage({super.key});

  @override
  State<TeacherSearchPage> createState() => _TeacherSearchPageState();
}

class _TeacherSearchPageState extends State<TeacherSearchPage> {
  int _currentNavIndex = 2;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final ApiClient _apiClient = ApiClient();

  final List<_CourseResult> _courses = <_CourseResult>[];
  bool _isLoading = false;
  String? _errorMessage;
  String _query = '';
  String _selectedCategory = 'All';
  String _sortBy = 'Newest';
  Timer? _debounce;

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
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.teacherCourses);
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
  void dispose() {
    _searchController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _searchController.addListener(_onSearchChanged);
    _minPriceController.addListener(_applyLocalFilters);
    _maxPriceController.addListener(_applyLocalFilters);
  }

  void _onSearchChanged() {
    final value = _searchController.text.trim();
    setState(() {
      _query = value.toLowerCase();
    });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _loadCourses);
  }

  void _applyLocalFilters() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _loadCourses() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      _setStateIfMounted(() {
        _errorMessage = 'Please log in to search courses.';
      });
      return;
    }

    _setStateIfMounted(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final instructor = HiveService.currentUserName;
      final params = <String, String>{};
      if (instructor != null && instructor.trim().isNotEmpty) {
        params['instructor'] = instructor;
      }
      if (_query.isNotEmpty) {
        params['search'] = _query;
      }

      final query = params.entries
          .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value)}')
          .join('&');
      final path = query.isEmpty ? '/api/v1/courses' : '/api/v1/courses?$query';

      final response = await _apiClient.getJson(path, token: token);
      final data = response['data'];
      if (data is List) {
        final mapped = data
            .whereType<Map<String, dynamic>>()
            .map(_CourseResult.fromJson)
            .toList();
        if (!mounted) {
          return;
        }
        setState(() {
          _courses
            ..clear()
            ..addAll(mapped);
          if (!_availableCategories.contains(_selectedCategory)) {
            _selectedCategory = 'All';
          }
        });
      } else {
        _setStateIfMounted(() {
          _errorMessage = 'Unexpected response format.';
        });
      }
    } on HttpException catch (err) {
      _setStateIfMounted(() {
        _errorMessage = err.message;
      });
    } catch (_) {
      _setStateIfMounted(() {
        _errorMessage = 'Unable to load courses.';
      });
    } finally {
      _setStateIfMounted(() {
        _isLoading = false;
      });
    }
  }

  String _resolveAssetUrl(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '';
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    final base = socketBaseUrl();
    if (raw.startsWith('/')) {
      return '$base$raw';
    }
    return '$base/$raw';
  }

  List<String> get _availableCategories {
    final categories = _courses
        .map((course) => course.category)
        .where((value) => value.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return <String>['All', ...categories];
  }

  List<_CourseResult> get _filteredResults {
    final minPrice = double.tryParse(_minPriceController.text.trim());
    final maxPrice = double.tryParse(_maxPriceController.text.trim());

    final filtered = _courses.where((course) {
      if (_selectedCategory != 'All' &&
          course.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }
      if (minPrice != null && course.price < minPrice) {
        return false;
      }
      if (maxPrice != null && course.price > maxPrice) {
        return false;
      }
      if (_query.isEmpty) {
        return true;
      }
      final q = _query.toLowerCase();
      return course.title.toLowerCase().contains(q) ||
          course.description.toLowerCase().contains(q) ||
          course.category.toLowerCase().contains(q);
    }).toList();

    switch (_sortBy) {
      case 'Oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Price: Low to High':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return filtered;
  }

  String _formatPrice(double value) {
    final rounded = value.round().toString();
    final formatted = rounded.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return 'Rs $formatted';
  }

  Widget _buildSearchResult(_CourseResult item) {
    final imageUrl = _resolveAssetUrl(item.imageUrl);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(
          AppRoutes.teacherCourseDetail,
          arguments: item.toDetailMap(),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl.isEmpty
                  ? Container(
                      width: 46,
                      height: 46,
                      color: AppColors.teacherChip,
                      child: const Icon(
                        Icons.menu_book,
                        color: AppColors.teacherPrimaryDark,
                        size: 22,
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 46,
                        height: 46,
                        color: AppColors.teacherChip,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.teacherMuted,
                          size: 20,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.teacherMuted,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatPrice(item.price),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E0),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.level,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFF8A00),
                  fontFamily: 'OpenSans',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredResults;

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
            'Search',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.teacherPrimaryDark,
              fontFamily: 'OpenSans',
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: 'Search',
                                border: InputBorder.none,
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'OpenSans',
                                ),
                              ),
                            ),
                          ),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFF0F2F7),
                            child: IconButton(
                              onPressed: _loadCourses,
                              icon: const Icon(Icons.tune, size: 16),
                              color: AppColors.teacherMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: _availableCategories.map((category) {
                        final isActive = category == _selectedCategory;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isActive
                                      ? AppColors.buttonText
                                      : AppColors.teacherMuted,
                                  fontFamily: 'OpenSans',
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) => Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _buildFilterControls(constraints.maxWidth),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Results',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.redAccent,
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton(
                                    onPressed: _loadCourses,
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          else if (results.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                'No courses found for these filters.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.teacherMuted,
                                  fontFamily: 'OpenSans',
                                ),
                              ),
                            )
                          else
                            ...results.map(_buildSearchResult),
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
      ),
    );
  }

  Widget _buildFilterControls(double width) {
    final isNarrow = width < 640;
    final isVeryNarrow = width < 460;

    Widget categoryField() {
      return DropdownButtonFormField<String>(
        key: ValueKey<String>('category-$_selectedCategory'),
        isExpanded: true,
        initialValue: _selectedCategory,
        decoration: _filterDecoration().copyWith(hintText: 'Category'),
        items: _availableCategories
            .map(
              (value) => DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) {
            return;
          }
          _setStateIfMounted(() {
            _selectedCategory = value;
          });
        },
      );
    }

    Widget sortField() {
      return DropdownButtonFormField<String>(
        key: ValueKey<String>('sort-$_sortBy'),
        isExpanded: true,
        initialValue: _sortBy,
        decoration: _filterDecoration().copyWith(hintText: 'Sort'),
        items: const [
          'Newest',
          'Oldest',
          'Price: Low to High',
          'Price: High to Low',
        ]
            .map(
              (value) => DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'OpenSans',
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) {
            return;
          }
          _setStateIfMounted(() {
            _sortBy = value;
          });
        },
      );
    }

    Widget minField() {
      return TextField(
        controller: _minPriceController,
        keyboardType: TextInputType.number,
        decoration: _filterDecoration().copyWith(hintText: 'Min price'),
      );
    }

    Widget maxField() {
      return TextField(
        controller: _maxPriceController,
        keyboardType: TextInputType.number,
        decoration: _filterDecoration().copyWith(hintText: 'Max price'),
      );
    }

    if (isVeryNarrow) {
      return Column(
        children: [
          categoryField(),
          const SizedBox(height: 8),
          sortField(),
          const SizedBox(height: 8),
          minField(),
          const SizedBox(height: 8),
          maxField(),
        ],
      );
    }

    if (isNarrow) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: categoryField()),
              const SizedBox(width: 8),
              Expanded(child: sortField()),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: minField()),
              const SizedBox(width: 8),
              Expanded(child: maxField()),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: categoryField()),
        const SizedBox(width: 8),
        Expanded(child: minField()),
        const SizedBox(width: 8),
        Expanded(child: maxField()),
        const SizedBox(width: 8),
        Expanded(child: sortField()),
      ],
    );
  }

  InputDecoration _filterDecoration() {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColors.background,
      hintStyle: const TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
        fontFamily: 'OpenSans',
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}

class _CourseResult {
  const _CourseResult({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.instructor,
    required this.durationHours,
    required this.lessonCount,
    required this.level,
    required this.price,
    required this.createdAt,
    required this.imageUrl,
    required this.features,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String instructor;
  final int durationHours;
  final int lessonCount;
  final String level;
  final double price;
  final DateTime createdAt;
  final String imageUrl;
  final String features;

  static _CourseResult fromJson(Map<String, dynamic> json) {
    final featuresValue = json['features'];
    String features = '';
    if (featuresValue is List) {
      features = featuresValue.map((e) => e.toString()).join(', ');
    } else if (featuresValue is String) {
      features = featuresValue;
    }

    return _CourseResult(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Course',
      description: json['description']?.toString() ?? 'Course details',
      category: json['category']?.toString() ?? 'General',
      instructor: json['instructorName']?.toString() ?? 'Instructor',
      durationHours: (json['durationHours'] as num?)?.toInt() ?? 0,
      lessonCount: (json['lessonCount'] as num?)?.toInt() ?? 0,
      level: json['level']?.toString() ?? 'Beginner',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString() ?? '',
      features: features,
    );
  }

  Map<String, dynamic> toDetailMap() {
    return {
      'id': id,
      '_id': id,
      'title': title,
      'description': description,
      'category': category,
      'level': level,
      'difficulty': level,
      'mentor': instructor,
      'instructorName': instructor,
      'weeks': '$durationHours hours',
      'progress': '0 / ${lessonCount == 0 ? 1 : lessonCount}',
      'students': '0 students',
      'status': 'Active',
      'price': price,
      'lessonCount': lessonCount,
      'imageUrl': imageUrl,
      'features': features,
    };
  }
}

