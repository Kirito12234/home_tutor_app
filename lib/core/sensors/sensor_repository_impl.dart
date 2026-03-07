import 'dart:async';

import 'sensor_datasource.dart';
import 'sensor_event.dart';
import 'sensor_repository.dart';

class SensorRepositoryImpl implements SensorRepository {
  SensorRepositoryImpl(this._dataSource);

  final SensorDataSource _dataSource;

  @override
  Stream<SensorSample> watchSensorEvents() {
    late StreamController<SensorSample> controller;
    StreamSubscription<dynamic>? accelerometerSubscription;
    StreamSubscription<dynamic>? userAccelerometerSubscription;
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
          userAccelerometerSubscription =
              _dataSource.userAccelerometerStream().listen(
            (event) {
              controller.add(
                SensorSample(
                  type: SensorEventType.userAccelerometer,
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
        await userAccelerometerSubscription?.cancel();
        await gyroscopeSubscription?.cancel();
        await controller.close();
      },
    );

    return controller.stream;
  }
}
