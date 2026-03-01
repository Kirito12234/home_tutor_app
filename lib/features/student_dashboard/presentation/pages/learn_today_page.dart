import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';

class LearnTodayPage extends StatefulWidget {
  const LearnTodayPage({super.key});

  @override
  State<LearnTodayPage> createState() => _LearnTodayPageState();
}

class _LearnTodayPageState extends State<LearnTodayPage> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _goalController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isSavingGoal = false;
  String? _errorMessage;

  int _goalMinutes = 60;
  int _todayMinutes = 0;
  int _scheduledCount = 0;
  int _completedCount = 0;
  int _cancelledCount = 0;

  final List<_SessionItem> _allTodaySessions = <_SessionItem>[];
  String _activeStatusTab = 'all';
  String _searchQuery = '';

  void _setStateIfMounted(VoidCallback fn) {
    if (!mounted) {
      return;
    }
    setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _goalMinutes = HiveService.learnedTodayGoalMinutes;
    _goalController.text = _goalMinutes.toString();
    _searchController.addListener(() {
      _setStateIfMounted(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    _goalController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _setStateIfMounted(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait<void>([
        _loadTodayProgress(),
        _loadTodaySessions(),
      ]);
    } on HttpException catch (err) {
      _setStateIfMounted(() {
        _errorMessage = err.message;
      });
    } catch (_) {
      _setStateIfMounted(() {
        _errorMessage = 'Unable to load learned today data.';
      });
    } finally {
      _setStateIfMounted(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTodayProgress() async {
    final response = await _apiClient.getJson(
      '/api/v1/progress',
      token: HiveService.authToken,
    );
    final data = response['data'];

    int derivedGoal = _goalMinutes;
    int todayMinutes = 0;

    if (data is List) {
      final today = DateTime.now();
      final todayKey = DateTime(today.year, today.month, today.day);
      for (final raw in data.whereType<Map<String, dynamic>>()) {
        final minutes = (raw['minutes'] as num?)?.toInt() ?? 0;
        if (minutes <= 0) {
          continue;
        }
        final dateRaw = raw['date']?.toString() ?? raw['createdAt']?.toString();
        final parsed = dateRaw != null ? DateTime.tryParse(dateRaw) : null;
        if (parsed == null) {
          continue;
        }
        final local = parsed.toLocal();
        final dayKey = DateTime(local.year, local.month, local.day);
        if (dayKey == todayKey) {
          todayMinutes += minutes;
        }
      }
    } else if (data is Map<String, dynamic>) {
      todayMinutes = (data['todayMinutes'] as num?)?.toInt() ?? 0;
      final apiGoal = (data['dailyGoalMinutes'] as num?)?.toInt() ??
          (data['goalMinutes'] as num?)?.toInt();
      if (apiGoal != null && apiGoal > 0) {
        derivedGoal = apiGoal;
      }
    }

    await HiveService.setLearnedTodayGoalMinutes(derivedGoal);
    _setStateIfMounted(() {
      _todayMinutes = todayMinutes;
      _goalMinutes = derivedGoal;
      _goalController.text = _goalMinutes.toString();
    });
  }

  Future<void> _loadTodaySessions() async {
    final response = await _apiClient.getJson(
      '/api/v1/sessions',
      token: HiveService.authToken,
    );
    final data = response['data'];
    if (data is! List) {
      return;
    }

    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);
    final mapped = data
        .whereType<Map<String, dynamic>>()
        .map(_SessionItem.fromJson)
        .where((session) {
      final local = session.startTime.toLocal();
      final dayKey = DateTime(local.year, local.month, local.day);
      return dayKey == todayKey;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final scheduled = mapped.where((s) => s.status == 'scheduled').length;
    final completed = mapped.where((s) => s.status == 'completed').length;
    final cancelled = mapped.where((s) => s.status == 'cancelled').length;

    _setStateIfMounted(() {
      _allTodaySessions
        ..clear()
        ..addAll(mapped);
      _scheduledCount = scheduled;
      _completedCount = completed;
      _cancelledCount = cancelled;
    });
  }

  Future<void> _saveGoal() async {
    final parsed = int.tryParse(_goalController.text.trim());
    if (parsed == null || parsed <= 0) {
      _showSnack('Enter a valid goal in minutes.');
      return;
    }

    _setStateIfMounted(() {
      _isSavingGoal = true;
      _errorMessage = null;
    });

    await HiveService.setLearnedTodayGoalMinutes(parsed);
    bool savedToApi = false;
    final body = <String, dynamic>{'dailyGoalMinutes': parsed};
    final endpoints = <String>[
      '/api/v1/progress/goal',
      '/api/v1/progress-goal',
      '/api/v1/progress',
    ];

    for (final endpoint in endpoints) {
      try {
        await _apiClient.putJson(
          endpoint,
          token: HiveService.authToken,
          body: body,
        );
        savedToApi = true;
        break;
      } catch (_) {
        try {
          await _apiClient.postJson(
            endpoint,
            token: HiveService.authToken,
            body: body,
          );
          savedToApi = true;
          break;
        } catch (_) {
          continue;
        }
      }
    }

    _setStateIfMounted(() {
      _goalMinutes = parsed;
      _isSavingGoal = false;
    });

    _showSnack(
      savedToApi
          ? 'Goal saved to database.'
          : 'Goal saved locally (API endpoint not available).',
    );
  }

  List<_SessionItem> get _filteredSessions {
    var list = _allTodaySessions;
    if (_activeStatusTab != 'all') {
      list = list.where((s) => s.status == _activeStatusTab).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (s) =>
                s.title.toLowerCase().contains(_searchQuery) ||
                s.peerName.toLowerCase().contains(_searchQuery),
          )
          .toList();
    }
    return list;
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final p = local.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $p';
  }

  Color _chipColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF0E9F6E);
      case 'cancelled':
        return const Color(0xFFE02424);
      default:
        return const Color(0xFF3A57EA);
    }
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final percent = _goalMinutes <= 0
        ? 0.0
        : (_todayMinutes / _goalMinutes).clamp(0.0, 1.0);
    final percentLabel = '${(percent * 100).round()}%';
    final sessions = _filteredSessions;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F5F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Learned today',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F1A39),
            fontFamily: 'OpenSans',
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Learned today',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F1A39),
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$_todayMinutes min / $_goalMinutes min',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontFamily: 'OpenSans',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        percentLabel,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3A57EA),
                          fontFamily: 'OpenSans',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      minHeight: 12,
                      value: percent,
                      backgroundColor: const Color(0xFFE6EBF2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF3A57EA),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _StatPill(label: 'Scheduled: $_scheduledCount'),
                      const SizedBox(width: 10),
                      _StatPill(label: 'Completed: $_completedCount'),
                      const SizedBox(width: 10),
                      _StatPill(label: 'Cancelled: $_cancelledCount'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 120,
                        child: TextField(
                          controller: _goalController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '60',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFD2DAE8)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  const BorderSide(color: Color(0xFFD2DAE8)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isSavingGoal ? null : _saveGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A57EA),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSavingGoal
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'OpenSans',
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F4FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search,
                            color: AppColors.textSecondary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search session or student',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          ),
                        ),
                        const Icon(Icons.tune,
                            color: AppColors.textSecondary, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _activeStatusTab == 'all',
                        onTap: () => _setStateIfMounted(() {
                          _activeStatusTab = 'all';
                        }),
                      ),
                      _FilterChip(
                        label: 'Scheduled',
                        selected: _activeStatusTab == 'scheduled',
                        onTap: () => _setStateIfMounted(() {
                          _activeStatusTab = 'scheduled';
                        }),
                      ),
                      _FilterChip(
                        label: 'Completed',
                        selected: _activeStatusTab == 'completed',
                        onTap: () => _setStateIfMounted(() {
                          _activeStatusTab = 'completed';
                        }),
                      ),
                      _FilterChip(
                        label: 'Cancelled',
                        selected: _activeStatusTab == 'cancelled',
                        onTap: () => _setStateIfMounted(() {
                          _activeStatusTab = 'cancelled';
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontFamily: 'OpenSans',
                        ),
                      ),
                    ),
                  if (!_isLoading && _errorMessage == null && sessions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'No matching sessions for today.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontFamily: 'OpenSans',
                        ),
                      ),
                    ),
                  if (!_isLoading)
                    ...sessions.map(
                      (item) => Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9EEFF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.calendar_month_outlined,
                                color: Color(0xFF3A57EA),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F1A39),
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${item.peerName} - ${_formatDateTime(item.startTime)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _chipColor(item.status).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                item.statusLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _chipColor(item.status),
                                  fontFamily: 'OpenSans',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF364152),
            fontFamily: 'OpenSans',
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3A57EA) : const Color(0xFFF1F4FA),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF364152),
            fontFamily: 'OpenSans',
          ),
        ),
      ),
    );
  }
}

class _SessionItem {
  const _SessionItem({
    required this.title,
    required this.peerName,
    required this.startTime,
    required this.status,
  });

  final String title;
  final String peerName;
  final DateTime startTime;
  final String status;

  String get statusLabel {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Scheduled';
    }
  }

  static _SessionItem fromJson(Map<String, dynamic> json) {
    final course = json['course'];
    final courseMap = course is Map<String, dynamic>
        ? course
        : <String, dynamic>{};
    final tutor = json['tutor'];
    final tutorMap = tutor is Map<String, dynamic> ? tutor : <String, dynamic>{};
    final student = json['student'];
    final studentMap =
        student is Map<String, dynamic> ? student : <String, dynamic>{};

    final startTime = DateTime.tryParse(json['startTime']?.toString() ?? '') ??
        DateTime.now();

    final title = courseMap['title']?.toString() ?? 'Session';
    final peerName = tutorMap['name']?.toString().trim().isNotEmpty == true
        ? tutorMap['name'].toString()
        : (studentMap['name']?.toString() ?? 'Tutor');

    final statusRaw = json['status']?.toString().toLowerCase() ?? 'scheduled';
    final status = (statusRaw == 'completed' || statusRaw == 'cancelled')
        ? statusRaw
        : 'scheduled';

    return _SessionItem(
      title: title,
      peerName: peerName,
      startTime: startTime,
      status: status,
    );
  }
}

