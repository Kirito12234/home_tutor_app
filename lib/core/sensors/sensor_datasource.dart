import 'package:sensors_plus/sensors_plus.dart';

class SensorDataSource {
  Stream<AccelerometerEvent> accelerometerStream() => accelerometerEventStream();

  Stream<UserAccelerometerEvent> userAccelerometerStream() =>
      userAccelerometerEventStream();

  Stream<GyroscopeEvent> gyroscopeStream() => gyroscopeEventStream();
}
