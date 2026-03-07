import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/emergency/emergency_alert_service.dart';
import 'sensor_provider.dart';

class ShakeDetectorWrapper extends ConsumerStatefulWidget {
  const ShakeDetectorWrapper({super.key});

  @override
  ConsumerState<ShakeDetectorWrapper> createState() =>
      _ShakeDetectorWrapperState();
}

class _ShakeDetectorWrapperState extends ConsumerState<ShakeDetectorWrapper> {
  bool _dialogOpen = false;
  ProviderSubscription<int>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ref.listenManual<int>(
      sensorViewModelProvider.select((state) => state.emergencyPromptNonce),
      (previous, next) => _handleEmergencyPrompt(previous, next),
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  Future<void> _handleEmergencyPrompt(int? previous, int next) async {
    if (previous == next || next == 0) {
      return;
    }
    if (_dialogOpen) {
      return;
    }

    final reason = ref.read(sensorViewModelProvider).emergencyTriggerReason;
    final isFlipToSos = reason == 'flip_face_down';

    _dialogOpen = true;
    try {
      if (!mounted) {
        return;
      }

      if (isFlipToSos) {
        final result = await EmergencyAlertService().sendEmergencySms();
        if (!mounted) {
          return;
        }

        final message = result.didOpenMessagingApp
            ? 'SOS draft opened in Messages. Press send if safe.'
            : (result.didCopyToClipboard
                ? 'Could not open Messages. SOS copied to clipboard.'
                : 'Could not open Messages for SOS.');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }

      final shouldSend = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(isFlipToSos ? 'SOS (Face Down)' : 'Send emergency alert?'),
            content: Text(
              isFlipToSos
                  ? 'Phone was kept face down. Send an emergency alert with your current location?'
                  : 'A strong shake was detected. Send an emergency alert with your current location?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Send'),
              ),
            ],
          );
        },
      );

      if (shouldSend != true || !mounted) {
        return;
      }

      final result = await EmergencyAlertService().sendEmergencySms();
      if (!mounted) {
        return;
      }

      final message = result.didOpenMessagingApp
          ? 'Opened Messages. Review and send your emergency alert.'
          : (result.didCopyToClipboard
              ? 'Could not open Messages. Alert copied to clipboard.'
              : 'Could not send emergency alert.');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
