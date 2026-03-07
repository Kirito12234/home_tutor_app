import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../hive/hive_service.dart';

class EmergencyAlertResult {
  const EmergencyAlertResult({
    required this.didOpenMessagingApp,
    required this.didCopyToClipboard,
    required this.message,
    this.error,
  });

  final bool didOpenMessagingApp;
  final bool didCopyToClipboard;
  final String message;
  final String? error;
}

class EmergencyAlertService {
  static const String defaultEmergencySmsNumber = '100';

  Future<EmergencyAlertResult> sendEmergencySms({
    String toNumber = defaultEmergencySmsNumber,
  }) async {
    final positionResult = await _tryGetCurrentPosition();

    final message = _buildMessage(positionResult.position);
    final smsUri = Uri(
      scheme: 'sms',
      path: toNumber,
      queryParameters: <String, String>{'body': message},
    );

    final didOpen = await launchUrl(
      smsUri,
      mode: LaunchMode.externalApplication,
    );

    if (didOpen) {
      return EmergencyAlertResult(
        didOpenMessagingApp: true,
        didCopyToClipboard: false,
        message: message,
        error: positionResult.error,
      );
    }

    await Clipboard.setData(ClipboardData(text: message));
    return EmergencyAlertResult(
      didOpenMessagingApp: false,
      didCopyToClipboard: true,
      message: message,
      error: positionResult.error ?? 'Could not open messaging app.',
    );
  }

  String _buildMessage(Position? position) {
    final name = HiveService.currentUserName;
    final role = HiveService.currentUserRole;

    final who = [
      if (name != null && name.trim().isNotEmpty) 'Name: ${name.trim()}',
      if (role != null && role.trim().isNotEmpty) 'Role: ${role.trim()}',
    ].join('\n');

    final locationLine = position == null
        ? 'Location: unavailable'
        : 'Location: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

    final mapLink = position == null
        ? null
        : 'Map: https://maps.google.com/?q=${position.latitude},${position.longitude}';

    return [
      'EMERGENCY ALERT',
      if (who.isNotEmpty) who,
      locationLine,
      if (mapLink != null) mapLink,
      'Time: ${DateTime.now().toIso8601String()}',
    ].join('\n');
  }

  Future<_PositionResult> _tryGetCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const _PositionResult(
        position: null,
        error: 'Location services disabled.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const _PositionResult(
        position: null,
        error: 'Location permission denied.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const _PositionResult(
        position: null,
        error: 'Location permission denied forever.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      return _PositionResult(position: position);
    } catch (e) {
      return _PositionResult(position: null, error: e.toString());
    }
  }
}

class _PositionResult {
  const _PositionResult({required this.position, this.error});

  final Position? position;
  final String? error;
}

