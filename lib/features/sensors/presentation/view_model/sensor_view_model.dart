import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/sensor_event.dart';
import '../../domain/repositories/sensor_repository.dart';
import 'sensor_state.dart';

class SensorViewModel extends StateNotifier<SensorState> {
  SensorViewModel(this._repository) : super(const SensorState()) {
    _subscribe();
  }

  final SensorRepository _repository;
  StreamSubscription<SensorSample>? _subscription;
  Timer? _cooldownTimer;
  Timer? _noDataTimer;
  bool _isCooldown = false;
  double? _previousGyroZ;
  double? _previousImpactMagnitude;
  bool _hasUserAccelerometer = false;
  bool _receivedAnySample = false;

  static const String _noDataMessage =
      'Sensors inactive. Emulator: Extended controls -> Virtual sensors.';

  static const double _impactMagnitudeThreshold = 9.0;
  static const double _impactDeltaThreshold = 7.0;
  static const double _gyroFastThreshold = 2.8;
  static const double _gyroZFlipDeltaThreshold = 3.5;

  void _subscribe() {
    try {
      _subscription = _repository.watchSensorEvents().listen(
        _onSensorEvent,
        onError: (_) {
          // Keep feature fail-safe; sensor stream errors should not crash app.
        },
      );
    } catch (_) {
      // Missing plugin or unsupported platform.
    }
    _startNoDataTimer();
  }

  void _startNoDataTimer() {
    _noDataTimer?.cancel();
    if (kIsWeb) {
      return;
    }
    final platform = defaultTargetPlatform;
    if (platform != TargetPlatform.android && platform != TargetPlatform.iOS) {
      return;
    }
    _noDataTimer = Timer(const Duration(seconds: 5), () {
      if (_receivedAnySample) {
        return;
      }
      state = state.copyWith(warningMessage: _noDataMessage);
    });
  }

  void _onSensorEvent(SensorSample sample) {
    if (!_receivedAnySample) {
      _receivedAnySample = true;
      _noDataTimer?.cancel();
      if (state.warningMessage == _noDataMessage) {
        clearMessage();
      }
    }

    if (_isCooldown) {
      return;
    }

    if (sample.type == SensorEventType.userAccelerometer) {
      _hasUserAccelerometer = true;
    }

    if (sample.type == SensorEventType.userAccelerometer ||
        (!_hasUserAccelerometer &&
            sample.type == SensorEventType.accelerometer)) {
      final force = sqrt(
        (sample.x * sample.x) + (sample.y * sample.y) + (sample.z * sample.z),
      );
      final delta = _previousImpactMagnitude == null
          ? 0
          : (force - _previousImpactMagnitude!).abs();
      _previousImpactMagnitude = force;

      // Prefer `userAccelerometer` (no gravity). If we only get plain
      // accelerometer (includes gravity), raise thresholds to avoid false
      // positives while still catching obvious impacts.
      final isGravityIncluded = sample.type == SensorEventType.accelerometer;
      final magnitudeThreshold =
          isGravityIncluded ? 15.0 : _impactMagnitudeThreshold;
      final deltaThreshold = isGravityIncluded ? 7.5 : _impactDeltaThreshold;

      if (force > magnitudeThreshold || delta > deltaThreshold) {
        state = state.copyWith(
          warningMessage:
              '⚠️ Impact detected (a=${force.toStringAsFixed(1)}).',
        );
        startCooldown();
      }
      return;
    }

    if (sample.type != SensorEventType.gyroscope) {
      return;
    }

    final gyroMagnitude = sqrt(
      (sample.x * sample.x) + (sample.y * sample.y) + (sample.z * sample.z),
    );
    final isFastRotation = gyroMagnitude > (_gyroFastThreshold * 1.25) ||
        sample.x.abs() > _gyroFastThreshold ||
        sample.y.abs() > _gyroFastThreshold ||
        sample.z.abs() > _gyroFastThreshold;
    final hasRapidZFlip =
        _previousGyroZ != null &&
        (sample.z - _previousGyroZ!).abs() > _gyroZFlipDeltaThreshold;
    _previousGyroZ = sample.z;

    if (isFastRotation || hasRapidZFlip) {
      state = state.copyWith(
        warningMessage:
            '⚠️ Sudden rotation detected (g=${gyroMagnitude.toStringAsFixed(1)}).',
      );
      startCooldown();
    }
  }

  void startCooldown() {
    _isCooldown = true;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(const Duration(seconds: 2), () {
      _isCooldown = false;
      clearMessage();
    });
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _noDataTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
