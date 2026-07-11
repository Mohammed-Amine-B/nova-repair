class RestoreConfirmationState {
  const RestoreConfirmationState({this.isRestoring = false, this.errorMessage});

  final bool isRestoring;
  final String? errorMessage;

  RestoreConfirmationState copyWith({
    bool? isRestoring,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return RestoreConfirmationState(
      isRestoring: isRestoring ?? this.isRestoring,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
