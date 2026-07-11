import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../printing/domain/entities/local_printer.dart';
import '../../printing/printing_providers.dart';
import '../domain/entities/shop_settings.dart';
import '../settings_providers.dart';
import 'settings_state.dart';

final settingsLoadProvider = FutureProvider.autoDispose<ShopSettings>((ref) {
  return ref.watch(shopSettingsRepositoryProvider).getSettings();
});

final settingsPrintersProvider = FutureProvider.autoDispose<List<LocalPrinter>>(
  (ref) {
    return ref.watch(localPrinterServiceProvider).listPrinters();
  },
);

final settingsControllerProvider =
    NotifierProvider.autoDispose<SettingsController, SettingsState>(
      SettingsController.new,
    );

class SettingsController extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    return const SettingsState();
  }

  void validateShopName(String value) {
    final error = _shopNameError(value);
    state = state.copyWith(
      shopNameError: error,
      clearShopNameError: error == null,
      clearSaveErrorMessage: true,
      clearSaveSuccessMessage: true,
    );
  }

  void clearFeedback() {
    state = state.copyWith(
      clearSaveErrorMessage: true,
      clearSaveSuccessMessage: true,
    );
  }

  Future<ShopSettings?> save({
    required ShopSettings currentSettings,
    required String shopName,
    required String shopSubtitle,
    required String phoneNumber,
    required String address,
    required String? defaultCustomerTicketPrinterId,
    required String? defaultDeviceLabelPrinterId,
  }) async {
    if (state.isSaving) {
      return null;
    }

    final shopNameError = _shopNameError(shopName);
    if (shopNameError != null) {
      state = state.copyWith(
        shopNameError: shopNameError,
        clearSaveErrorMessage: true,
        clearSaveSuccessMessage: true,
      );
      return null;
    }

    state = state.copyWith(
      isSaving: true,
      clearShopNameError: true,
      clearSaveErrorMessage: true,
      clearSaveSuccessMessage: true,
    );

    try {
      final updatedSettings = currentSettings.copyWith(
        shopName: shopName,
        shopSubtitle: shopSubtitle,
        phoneNumber: phoneNumber,
        address: address,
        defaultCustomerTicketPrinterId: defaultCustomerTicketPrinterId,
        defaultDeviceLabelPrinterId: defaultDeviceLabelPrinterId,
      );
      final savedSettings = await ref
          .read(shopSettingsRepositoryProvider)
          .saveSettings(updatedSettings);

      state = state.copyWith(
        isSaving: false,
        saveSuccessMessage: 'Settings saved successfully.',
      );
      return savedSettings;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        saveErrorMessage: 'Settings could not be saved. Please try again.',
      );
      return null;
    }
  }

  String? _shopNameError(String value) {
    return value.trim().isEmpty ? 'Shop name is required.' : null;
  }
}
