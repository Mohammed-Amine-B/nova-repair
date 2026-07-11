class SettingsState {
  const SettingsState({
    this.shopNameError,
    this.saveSuccessMessage,
    this.saveErrorMessage,
    this.isSaving = false,
  });

  final String? shopNameError;
  final String? saveSuccessMessage;
  final String? saveErrorMessage;
  final bool isSaving;

  SettingsState copyWith({
    String? shopNameError,
    bool clearShopNameError = false,
    String? saveSuccessMessage,
    bool clearSaveSuccessMessage = false,
    String? saveErrorMessage,
    bool clearSaveErrorMessage = false,
    bool? isSaving,
  }) {
    return SettingsState(
      shopNameError: clearShopNameError
          ? null
          : shopNameError ?? this.shopNameError,
      saveSuccessMessage: clearSaveSuccessMessage
          ? null
          : saveSuccessMessage ?? this.saveSuccessMessage,
      saveErrorMessage: clearSaveErrorMessage
          ? null
          : saveErrorMessage ?? this.saveErrorMessage,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
