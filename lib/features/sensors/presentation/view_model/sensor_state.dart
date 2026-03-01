class SensorState {
  const SensorState({this.warningMessage});

  final String? warningMessage;

  SensorState copyWith({String? warningMessage, bool clearMessage = false}) {
    return SensorState(
      warningMessage:
          clearMessage ? null : warningMessage ?? this.warningMessage,
    );
  }
}
