import 'package:sensors_plus/sensors_plus.dart';

class SensorDataSource {
  // ignore: deprecated_member_use
  Stream<AccelerometerEvent> accelerometerStream() => accelerometerEvents;

  // ignore: deprecated_member_use
  Stream<UserAccelerometerEvent> userAccelerometerStream() =>
      userAccelerometerEvents;

  // ignore: deprecated_member_use
  Stream<GyroscopeEvent> gyroscopeStream() => gyroscopeEvents;
}
