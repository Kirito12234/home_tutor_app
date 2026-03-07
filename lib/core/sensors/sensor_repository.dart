import 'sensor_event.dart';

abstract class SensorRepository {
  Stream<SensorSample> watchSensorEvents();
}
