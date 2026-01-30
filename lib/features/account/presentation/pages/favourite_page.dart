import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/services/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';

class FavouritePage extends StatefulWidget {
  const FavouritePage({Key? key}) : super(key: key);

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, String>> _favourites = [];

  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  Future<void> _loadFavourites() async {
    final token = HiveService.authToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _errorMessage = 'Please log in to view favourites.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.getJson(
        '/api/v1/favorites',
        token: token,
      );
      final data = response['data'];
      if (data is List) {
        final mapped = data
            .whereType<Map<String, dynamic>>()
            .map((favorite) {
              final course = favorite['course'];
              final courseMap =
                  course is Map<String, dynamic> ? course : <String, dynamic>{};
              final title = courseMap['title']?.toString() ?? 'Course';
              final subtitle =
                  courseMap['description']?.toString() ??
                  courseMap['category']?.toString() ??
                  'Saved course';
              return {
                'id': favorite['_id']?.toString() ?? favorite['id']?.toString() ?? '',
                'title': title,
                'subtitle': subtitle,
              };
            })
            .toList();
        setState(() {
          _favourites = mapped;
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
        _errorMessage = 'Unable to load favourites.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Favourite',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
      ),
      body: _isLoading
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
                  children: _favourites
                      .map(
                        (item) => Container(
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
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.categoryBeige,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: AppColors.durationOrange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] ?? 'Course',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['subtitle'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.bookmark_remove,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () async {
                                  final id = item['id'];
                                  if (id == null || id.isEmpty) {
                                    return;
                                  }
                                  final token = HiveService.authToken;
                                  if (token == null || token.isEmpty) {
                                    return;
                                  }
                                  try {
                                    await _apiClient.deleteJson(
                                      '/api/v1/favorites/$id',
                                      token: token,
                                    );
                                  } catch (_) {
                                    // ignore
                                  }
                                  setState(() {
                                    _favourites.removeWhere(
                                      (fav) => fav['id'] == id,
                                    );
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Removed from favourites'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
    );
  }
}
