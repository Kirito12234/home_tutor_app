import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/services/hive/hive_service.dart';
import '../../../../core/widgets/primary_button.dart';
import '../widgets/week_record_dots.dart';

class ClockingInModal extends StatefulWidget {
  const ClockingInModal({Key? key}) : super(key: key);

  @override
  State<ClockingInModal> createState() => _ClockingInModalState();
}

class _ClockingInModalState extends State<ClockingInModal> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  String? _errorMessage;
  int _todayMinutes = 0;
  int _totalMinutes = 0;
  int _totalDays = 0;
  int _activeDaysThisWeek = 0;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final paths = <String>[
        '/api/v1/progress',
        '/api/v1/progress/summary',
        '/api/v1/learned-today',
      ];

      Map<String, dynamic>? response;
      for (final path in paths) {
        try {
          response = await _apiClient.getJson(
            path,
            token: HiveService.authToken,
          );
          break;
        } on HttpException catch (err) {
          if (err.statusCode == 404 || err.statusCode == 405) {
            continue;
          }
          rethrow;
        }
      }

      if (response == null) {
        _applyProgress(const <Map<String, dynamic>>[]);
        return;
      }

      final data = response['data'];
      if (data is List) {
        _applyProgress(data.whereType<Map<String, dynamic>>().toList());
      } else if (data is Map<String, dynamic>) {
        final todayMinutes = (data['todayMinutes'] as num?)?.toInt() ?? 0;
        final totalMinutes = (data['totalMinutes'] as num?)?.toInt() ?? 0;
        final totalDays = (data['totalDays'] as num?)?.toInt() ?? 0;
        final weekDays = (data['activeDaysThisWeek'] as num?)?.toInt() ?? 0;
        _todayMinutes = todayMinutes;
        _totalMinutes = totalMinutes;
        _totalDays = totalDays;
        _activeDaysThisWeek = weekDays;
      }
    } on HttpException catch (err) {
      // Do not show route-missing details to user on this modal.
      if (err.statusCode != 404 && err.statusCode != 405) {
        _errorMessage = 'Unable to load progress.';
      }
    } catch (_) {
      _errorMessage = 'Unable to load progress.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyProgress(List<Map<String, dynamic>> entries) {
    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final startOfWeek = todayKey.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final totalDays = <DateTime>{};
    final weekDays = <DateTime>{};
    var todayMinutes = 0;
    var totalMinutes = 0;

    for (final entry in entries) {
      final minutes = entry['minutes'];
      if (minutes is! num || minutes <= 0) {
        continue;
      }
      final dateRaw = entry['date']?.toString();
      final parsed = dateRaw != null ? DateTime.tryParse(dateRaw) : null;
      if (parsed == null) {
        continue;
      }
      final localDate = parsed.toLocal();
      final dayKey = DateTime(localDate.year, localDate.month, localDate.day);

      totalMinutes += minutes.round();
      totalDays.add(dayKey);

      if (dayKey == todayKey) {
        todayMinutes += minutes.round();
      }

      if (!dayKey.isBefore(startOfWeek) && dayKey.isBefore(endOfWeek)) {
        weekDays.add(dayKey);
      }
    }

    _todayMinutes = todayMinutes;
    _totalMinutes = totalMinutes;
    _totalDays = totalDays.length;
    _activeDaysThisWeek = weekDays.length;
  }

  @override
  Widget build(BuildContext context) {
    final totalHours = _totalMinutes ~/ 60;
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Clocking in!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'GOOD JOB!',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Learned today',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_todayMinutes} min',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            'Total hours',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalHours hrs',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Total days',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_totalDays days',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Record of this week',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: 'OpenSans',
                    ),
                  ),
                  const SizedBox(height: 16),
                  WeekRecordDots(activeDays: _activeDaysThisWeek),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Share',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Shared!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


