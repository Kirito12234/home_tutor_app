enum SensorEventType { accelerometer, userAccelerometer, gyroscope }

class SensorSample {
  const SensorSample({
    required this.type,
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  final SensorEventType type;
  final double x;
  final double y;
  final double z;
  final DateTime timestamp;
}
