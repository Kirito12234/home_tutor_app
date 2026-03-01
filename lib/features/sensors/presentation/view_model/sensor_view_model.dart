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
  double? _previousAccelMagnitude;
  bool _receivedAnySample = false;

  static const String _noDataMessage =
      'Sensors inactive. Emulator: Extended controls -> Virtual sensors.';

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

    if (sample.type == SensorEventType.accelerometer) {
      final force = sqrt(
        (sample.x * sample.x) + (sample.y * sample.y) + (sample.z * sample.z),
      );
      final delta = _previousAccelMagnitude == null
          ? 0
          : (force - _previousAccelMagnitude!).abs();
      _previousAccelMagnitude = force;

      // Resting magnitude is ~9.8. Keep thresholds low enough so users can
      // observe this working on real devices and emulators.
      if (force > 14 || delta > 6) {
        state = state.copyWith(
          warningMessage: '⚠️ Impact detected! Device hit something.',
        );
        startCooldown();
      }
      return;
    }

    final isFastRotation =
        sample.x.abs() > 2 || sample.y.abs() > 2 || sample.z.abs() > 2;
    final hasRapidZFlip =
        _previousGyroZ != null && (sample.z - _previousGyroZ!).abs() > 3;
    _previousGyroZ = sample.z;

    if (isFastRotation || hasRapidZFlip) {
      state = state.copyWith(
        warningMessage: '⚠️ Sudden rotation detected!',
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
