import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/api/api_client.dart';
import '../../domain/entities/message_notification.dart';
import '../providers/notifications_provider.dart';
import '../widgets/segmented_tabs.dart';
import '../widgets/message_card.dart';
import '../widgets/notification_tile.dart';
import '../../../student_dashboard/presentation/widgets/bottom_nav.dart';
import '../../../student_courses/data/models/course_model.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  int _currentTab = 0;
  int _currentNavIndex = 3;
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();

  String get _screenTitle => _currentTab == 0 ? 'Messages' : 'Notifications';
  String get _searchQuery => _searchController.text.trim().toLowerCase();
  List<MessageNotification> _filteredThreads(List<MessageNotification> threads) {
    final q = _searchQuery;
    if (q.isEmpty) {
      return threads;
    }
    return threads.where((t) => t.name.toLowerCase().contains(q)).toList();
  }

  Future<bool> _handleBack() async {
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    return false;
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
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.courses);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.searchResults);
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.account);
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsViewModelProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openNotification(NotificationItem notif) async {
    if (notif.type != 'course') {
      return;
    }
    final courseId = notif.data?['courseId']?.toString();
    if (courseId == null || courseId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Course not found.')),
      );
      return;
    }
    try {
      final response = await _apiClient.getJson('/api/v1/courses/$courseId');
      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response');
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamed(
        AppRoutes.courseDetail,
        arguments: CourseModel.fromJson(data).toEntity(),
      );
    } on HttpException catch (err) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.message)),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open course.')),
      );
    }
  }

  void _openThread(MessageNotification thread) {
    Navigator.of(context).pushNamed(
      AppRoutes.messageThread,
      arguments: thread,
    );
  }

  Future<void> _searchAndOpenThread() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ref.read(notificationsViewModelProvider.notifier).clearCandidates();
      if (mounted) {
        setState(() {});
      }
      return;
    }

    final state = ref.read(notificationsViewModelProvider);
    final matches = state.threads
        .where(
          (thread) => thread.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    final exact = matches.where((t) => t.name.toLowerCase() == query.toLowerCase()).toList();
    if (exact.isNotEmpty) {
      _openThread(exact.first);
      return;
    }
    if (matches.length == 1) {
      _openThread(matches.first);
      return;
    }

    final viewModel = ref.read(notificationsViewModelProvider.notifier);
    await viewModel.searchTeachers(query);
    final candidates = ref.read(notificationsViewModelProvider).searchCandidates;
    if (!mounted) {
      return;
    }
    setState(() {});
    if (candidates.length == 1) {
      final thread = await viewModel.createOrOpenThread(candidates.first);
      if (thread != null && mounted) {
        _openThread(thread);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(notificationsViewModelProvider);
    final filteredThreads = _filteredThreads(vmState.threads);
    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Text(
            _screenTitle,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'OpenSans',
            ),
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 8),
            SegmentedTabs(
              selectedIndex: _currentTab,
              onTap: (index) {
                setState(() {
                  _currentTab = index;
                  if (index != 0) {
                    ref
                        .read(notificationsViewModelProvider.notifier)
                        .clearCandidates();
                  }
                });
              },
              showNotificationDot: _currentTab == 0,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: vmState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : vmState.errorMessage != null
                      ? Center(
                          child: Text(
                            vmState.errorMessage!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.redAccent,
                              fontFamily: 'OpenSans',
                            ),
                          ),
                        )
                      : _currentTab == 0
                          ? ListView(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        decoration: InputDecoration(
                                          hintText: 'Search teacher name',
                                          isDense: true,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: AppColors.divider,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(
                                              color: AppColors.divider,
                                            ),
                                          ),
                                        ),
                                        onSubmitted: (_) => _searchAndOpenThread(),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      height: 36,
                                      child: ElevatedButton(
                                        onPressed: vmState.isSearchingOrCreating
                                            ? null
                                            : _searchAndOpenThread,
                                        child: Text(
                                          vmState.isSearchingOrCreating
                                              ? '...'
                                              : 'Search',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...filteredThreads.map((message) {
                                  return MessageCard(message: message);
                                }),
                                if (filteredThreads.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Text(
                                      'No messages found.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontFamily: 'OpenSans',
                                      ),
                                    ),
                                  ),
                                if (vmState.searchCandidates.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Teachers',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      fontFamily: 'OpenSans',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...vmState.searchCandidates.map((candidate) {
                                    return ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(candidate.name),
                                      trailing: TextButton(
                                        onPressed: vmState.isSearchingOrCreating
                                            ? null
                                            : () async {
                                                final thread = await ref
                                                    .read(
                                                      notificationsViewModelProvider
                                                          .notifier,
                                                    )
                                                    .createOrOpenThread(candidate);
                                                if (thread != null &&
                                                    mounted) {
                                                  _openThread(thread);
                                                }
                                              },
                                        child: const Text('Open'),
                                      ),
                                      onTap: vmState.isSearchingOrCreating
                                          ? null
                                          : () async {
                                              final thread = await ref
                                                  .read(
                                                    notificationsViewModelProvider
                                                        .notifier,
                                                  )
                                                  .createOrOpenThread(candidate);
                                              if (thread != null && mounted) {
                                                _openThread(thread);
                                              }
                                            },
                                    );
                                  }),
                                ],
                              ],
                            )
                          : ListView(
                              children: vmState.notifications.map((notif) {
                                return NotificationTile(
                                  notification: notif,
                                  onTap: () => _openNotification(notif),
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
      ),
    );
  }
}

