import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/local/notifications_local_datasource.dart';
import '../../data/datasources/remote/notifications_remote_datasource.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../view_model/notifications_state.dart';
import '../view_model/notifications_view_model.dart';

final notificationsLocalDataSourceProvider =
    Provider<NotificationsLocalDataSource>((ref) {
  return const NotificationsLocalDataSource();
});

final notificationsRemoteDataSourceProvider =
    Provider<NotificationsRemoteDataSource>((ref) {
  return NotificationsRemoteDataSource();
});

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final remote = ref.watch(notificationsRemoteDataSourceProvider);
  final local = ref.watch(notificationsLocalDataSourceProvider);
  return NotificationsRepositoryImpl(remote: remote, local: local);
});

final notificationsViewModelProvider = StateNotifierProvider.autoDispose<
    NotificationsViewModel, NotificationsState>((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  return NotificationsViewModel(repo);
});

