import 'dart:async';

import '../../domain/entities/sensor_event.dart';
import '../../domain/repositories/sensor_repository.dart';
import '../datasources/sensor_datasource.dart';

class SensorRepositoryImpl implements SensorRepository {
  SensorRepositoryImpl(this._dataSource);

  final SensorDataSource _dataSource;

  @override
  Stream<SensorSample> watchSensorEvents() {
    late StreamController<SensorSample> controller;
    StreamSubscription<dynamic>? accelerometerSubscription;
    StreamSubscription<dynamic>? gyroscopeSubscription;

    controller = StreamController<SensorSample>.broadcast(
      onListen: () {
        try {
          accelerometerSubscription = _dataSource.accelerometerStream().listen(
            (event) {
              controller.add(
                SensorSample(
                  type: SensorEventType.accelerometer,
                  x: event.x,
                  y: event.y,
                  z: event.z,
                  timestamp: DateTime.now(),
                ),
              );
            },
            onError: controller.addError,
          );
        } catch (err, stack) {
          controller.addError(err, stack);
        }

        try {
          gyroscopeSubscription = _dataSource.gyroscopeStream().listen(
            (event) {
              controller.add(
                SensorSample(
                  type: SensorEventType.gyroscope,
                  x: event.x,
                  y: event.y,
                  z: event.z,
                  timestamp: DateTime.now(),
                ),
              );
            },
            onError: controller.addError,
          );
        } catch (err, stack) {
          controller.addError(err, stack);
        }
      },
      onCancel: () async {
        await accelerometerSubscription?.cancel();
        await gyroscopeSubscription?.cancel();
        await controller.close();
      },
    );

    return controller.stream;
  }
}
