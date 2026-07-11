class OnlineTrackingConnectionState {
  const OnlineTrackingConnectionState({
    this.secretInputError,
    this.errorMessage,
    this.successMessage,
    this.isSubmitting = false,
  });

  final String? secretInputError;
  final String? errorMessage;
  final String? successMessage;
  final bool isSubmitting;

  OnlineTrackingConnectionState copyWith({
    String? secretInputError,
    bool clearSecretInputError = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? successMessage,
    bool clearSuccessMessage = false,
    bool? isSubmitting,
  }) {
    return OnlineTrackingConnectionState(
      secretInputError: clearSecretInputError
          ? null
          : secretInputError ?? this.secretInputError,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      successMessage: clearSuccessMessage
          ? null
          : successMessage ?? this.successMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
