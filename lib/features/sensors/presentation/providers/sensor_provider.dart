import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/sensor_datasource.dart';
import '../../data/repositories/sensor_repository_impl.dart';
import '../../domain/repositories/sensor_repository.dart';
import '../view_model/sensor_state.dart';
import '../view_model/sensor_view_model.dart';

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
