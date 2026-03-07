class SensorState {
  const SensorState({
    this.warningMessage,
    this.emergencyPromptNonce = 0,
    this.emergencyTriggerReason,
  });

  final String? warningMessage;
  final int emergencyPromptNonce;
  final String? emergencyTriggerReason;

  SensorState copyWith({
    String? warningMessage,
    int? emergencyPromptNonce,
    String? emergencyTriggerReason,
    bool clearMessage = false,
  }) {
    return SensorState(
      warningMessage:
          clearMessage ? null : warningMessage ?? this.warningMessage,
      emergencyPromptNonce: emergencyPromptNonce ?? this.emergencyPromptNonce,
      emergencyTriggerReason:
          emergencyTriggerReason ?? this.emergencyTriggerReason,
    );
  }
}
