import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sensor_provider.dart';

class SensorWarningWidget extends ConsumerWidget {
  const SensorWarningWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warningMessage = ref.watch(sensorViewModelProvider).warningMessage;
    final isVisible = warningMessage != null && warningMessage.isNotEmpty;

    return IgnorePointer(
      ignoring: true,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.topCenter,
            child: AnimatedOpacity(
              opacity: isVisible ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: AnimatedSlide(
                offset: isVisible ? Offset.zero : const Offset(0, -0.2),
                duration: const Duration(milliseconds: 250),
                child: isVisible
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x33000000),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          warningMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
