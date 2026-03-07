import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sensor_datasource.dart';
import 'sensor_repository.dart';
import 'sensor_repository_impl.dart';
import 'sensor_state.dart';
import 'sensor_view_model.dart';

final sensorDataSourceProvider = Provider<SensorDataSource>((ref) {
  return SensorDataSource();
});

final sensorRepositoryProvider = Provider<SensorRepository>((ref) {
  final dataSource = ref.watch(sensorDataSourceProvider);
  return SensorRepositoryImpl(dataSource);
});

final sensorViewModelProvider =
    StateNotifierProvider<SensorViewModel, SensorState>((ref) {
  final repository = ref.watch(sensorRepositoryProvider);
  return SensorViewModel(repository);
});
