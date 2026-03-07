import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sensor_event.dart';
import 'sensor_repository.dart';
import 'sensor_state.dart';

class SensorViewModel extends StateNotifier<SensorState> {
  SensorViewModel(this._repository) : super(const SensorState()) {
    _subscribe();
  }

  final SensorRepository _repository;
  StreamSubscription<SensorSample>? _subscription;
  Timer? _cooldownTimer;
  Timer? _noDataTimer;
  Timer? _emergencyCooldownTimer;
  bool _isCooldown = false;
  bool _isEmergencyCooldown = false;
  double? _previousGyroZ;
  double? _previousImpactMagnitude;
  bool _hasUserAccelerometer = false;
  bool _receivedAnySample = false;
  int? _shakeWindowStartMs;
  int? _lastShakeMs;
  int _shakeCount = 0;
  int? _lastRotationMs;
  bool _isFaceDown = false;
  bool _faceDownTriggered = false;
  bool _flipArmed = false;
  double? _previousAccelZ;
  Timer? _faceDownTimer;

  static const String _noDataMessage =
      'Sensors inactive. Emulator: Extended controls -> Virtual sensors.';

  static const double _impactMagnitudeThreshold = 9.0;
  static const double _impactDeltaThreshold = 7.0;
  static const double _gyroFastThreshold = 2.8;
  static const double _gyroZFlipDeltaThreshold = 3.5;
  static const double _gravity = 9.80665;

  static const double _shakeThresholdWithGravityG = 2.7;
  static const double _shakeThresholdNoGravityG = 1.2;
  static const int _shakeCountToTrigger = 3;
  static const Duration _shakeSlop = Duration(milliseconds: 300);
  static const Duration _shakeWindow = Duration(milliseconds: 900);
  static const Duration _emergencyCooldown = Duration(seconds: 6);

  static const double _faceDownZThreshold = -7.5;
  static const double _faceDownXyThreshold = 6.0;
  static const Duration _faceDownHold = Duration(milliseconds: 900);
  static const Duration _flipRotationWindow = Duration(milliseconds: 1500);
  static const double _gyroFlipDetectThreshold = 1.8;

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

    if (sample.type == SensorEventType.userAccelerometer) {
      _hasUserAccelerometer = true;
    }

    if (sample.type == SensorEventType.accelerometer) {
      final previousZ = _previousAccelZ;
      _updateFaceDownFromAccelerometer(sample, previousZ: previousZ);
      _previousAccelZ = sample.z;

      if (_hasUserAccelerometer) {
        return;
      }

      final force = sqrt(
        (sample.x * sample.x) + (sample.y * sample.y) + (sample.z * sample.z),
      );
      final delta = _previousImpactMagnitude == null
          ? 0
          : (force - _previousImpactMagnitude!).abs();
      _previousImpactMagnitude = force;

      _detectShake(force / _gravity, gravityIncluded: true);

      if (!_isCooldown && (force > 15.0 || delta > 7.5)) {
        state = state.copyWith(
          warningMessage:
              'Warning: impact detected (a=${force.toStringAsFixed(1)}).',
        );
        startCooldown();
      }
      return;
    }

    if (sample.type == SensorEventType.userAccelerometer) {
      final force = sqrt(
        (sample.x * sample.x) + (sample.y * sample.y) + (sample.z * sample.z),
      );
      final delta = _previousImpactMagnitude == null
          ? 0
          : (force - _previousImpactMagnitude!).abs();
      _previousImpactMagnitude = force;

      _detectShake(force / _gravity, gravityIncluded: false);

      if (!_isCooldown &&
          (force > _impactMagnitudeThreshold || delta > _impactDeltaThreshold)) {
        state = state.copyWith(
          warningMessage:
              'Warning: impact detected (a=${force.toStringAsFixed(1)}).',
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

    if (gyroMagnitude > _gyroFlipDetectThreshold) {
      _lastRotationMs = sample.timestamp.millisecondsSinceEpoch;
    }

    final isFastRotation = gyroMagnitude > (_gyroFastThreshold * 1.25) ||
        sample.x.abs() > _gyroFastThreshold ||
        sample.y.abs() > _gyroFastThreshold ||
        sample.z.abs() > _gyroFastThreshold;
    final hasRapidZFlip =
        _previousGyroZ != null &&
        (sample.z - _previousGyroZ!).abs() > _gyroZFlipDeltaThreshold;
    _previousGyroZ = sample.z;

    if (!_isCooldown && (isFastRotation || hasRapidZFlip)) {
      state = state.copyWith(
        warningMessage:
            'Warning: sudden rotation detected (g=${gyroMagnitude.toStringAsFixed(1)}).',
      );
      startCooldown();
    }
  }

  void _detectShake(double gForce, {required bool gravityIncluded}) {
    if (_isEmergencyCooldown) {
      return;
    }

    final threshold =
        gravityIncluded ? _shakeThresholdWithGravityG : _shakeThresholdNoGravityG;
    if (gForce < threshold) {
      return;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (_lastShakeMs != null &&
        (nowMs - _lastShakeMs!) < _shakeSlop.inMilliseconds) {
      return;
    }
    _lastShakeMs = nowMs;

    if (_shakeWindowStartMs == null ||
        (nowMs - _shakeWindowStartMs!) > _shakeWindow.inMilliseconds) {
      _shakeWindowStartMs = nowMs;
      _shakeCount = 1;
    } else {
      _shakeCount += 1;
    }

    if (_shakeCount < _shakeCountToTrigger) {
      return;
    }

    _shakeWindowStartMs = null;
    _lastShakeMs = null;
    _shakeCount = 0;

    _triggerEmergency('shake');
  }

  void _updateFaceDownFromAccelerometer(
    SensorSample sample, {
    required double? previousZ,
  }) {
    final xy = sqrt((sample.x * sample.x) + (sample.y * sample.y));
    final isFaceDown =
        sample.z < _faceDownZThreshold && xy < _faceDownXyThreshold;

    if (isFaceDown == _isFaceDown) {
      return;
    }

    _isFaceDown = isFaceDown;
    _faceDownTimer?.cancel();

    if (!isFaceDown) {
      _faceDownTriggered = false;
      _flipArmed = false;
      return;
    }

    if (_faceDownTriggered) {
      return;
    }

    final nowMs = sample.timestamp.millisecondsSinceEpoch;
    final gyroRecent = _lastRotationMs != null &&
        (nowMs - _lastRotationMs!) <= _flipRotationWindow.inMilliseconds;
    final accelFlip = previousZ != null && previousZ > 3.0;
    _flipArmed = gyroRecent || accelFlip;
    if (!_flipArmed) {
      return;
    }

    _faceDownTimer = Timer(_faceDownHold, () {
      if (!_isFaceDown || _faceDownTriggered || _isEmergencyCooldown) {
        return;
      }
      _faceDownTriggered = true;
      _triggerEmergency('flip_face_down');
    });
  }

  void _triggerEmergency(String reason) {
    _isEmergencyCooldown = true;
    _emergencyCooldownTimer?.cancel();
    _emergencyCooldownTimer = Timer(_emergencyCooldown, () {
      _isEmergencyCooldown = false;
    });

    state = state.copyWith(
      emergencyTriggerReason: reason,
      emergencyPromptNonce: state.emergencyPromptNonce + 1,
    );
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
    _emergencyCooldownTimer?.cancel();
    _faceDownTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
