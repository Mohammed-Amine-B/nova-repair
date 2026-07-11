import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/create_repair_input.dart';
import '../domain/entities/repair.dart';
import '../repair_providers.dart';
import 'new_repair_state.dart';

final newRepairControllerProvider =
    NotifierProvider<NewRepairController, NewRepairState>(
      NewRepairController.new,
    );

class NewRepairController extends Notifier<NewRepairState> {
  @override
  NewRepairState build() {
    return const NewRepairState();
  }

  void validateDeviceType(String value) {
    final error = _requiredTextError(value, 'Device type is required.');
    state = state.copyWith(
      deviceTypeError: error,
      clearDeviceTypeError: error == null,
      clearSubmissionError: true,
    );
  }

  void validateReportedProblem(String value) {
    final error = _requiredTextError(value, 'Reported problem is required.');
    state = state.copyWith(
      reportedProblemError: error,
      clearReportedProblemError: error == null,
      clearSubmissionError: true,
    );
  }

  void validatePrice(String value) {
    final error = _priceError(value);
    state = state.copyWith(
      priceError: error,
      clearPriceError: error == null,
      clearSubmissionError: true,
    );
  }

  Future<Repair?> submit({
    required NewRepairSubmitAction action,
    required String customerName,
    required String customerPhone,
    required String deviceType,
    required String brand,
    required String model,
    required String reportedProblem,
    required String receivedAccessories,
    required String deviceAccessInfo,
    required String priceText,
    required String internalNotes,
    required String customerMessage,
  }) async {
    if (state.isSubmitting) {
      return null;
    }

    final deviceTypeError = _requiredTextError(
      deviceType,
      'Device type is required.',
    );
    final reportedProblemError = _requiredTextError(
      reportedProblem,
      'Reported problem is required.',
    );
    final priceError = _priceError(priceText);

    if (deviceTypeError != null ||
        reportedProblemError != null ||
        priceError != null) {
      state = state.copyWith(
        deviceTypeError: deviceTypeError,
        clearDeviceTypeError: deviceTypeError == null,
        reportedProblemError: reportedProblemError,
        clearReportedProblemError: reportedProblemError == null,
        priceError: priceError,
        clearPriceError: priceError == null,
        clearSubmissionError: true,
        clearCreatedRepair: true,
      );
      return null;
    }

    state = state.copyWith(
      isSubmitting: true,
      activeSubmitAction: action,
      clearSubmissionError: true,
      clearCreatedRepair: true,
    );

    try {
      final repair = await ref
          .read(createRepairUseCaseProvider)
          .call(
            CreateRepairInput(
              customerName: customerName,
              customerPhone: customerPhone,
              deviceType: deviceType,
              brand: brand,
              model: model,
              reportedProblem: reportedProblem,
              receivedAccessories: receivedAccessories,
              deviceAccessInfo: deviceAccessInfo,
              priceAmount: _parsePrice(priceText),
              internalNotes: internalNotes,
              customerMessage: customerMessage,
            ),
          );

      state = state.copyWith(
        isSubmitting: false,
        clearActiveSubmitAction: true,
        createdRepair: repair,
      );
      return repair;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        clearActiveSubmitAction: true,
        submissionError: 'Repair could not be saved. Please try again.',
      );
      return null;
    }
  }

  String? _requiredTextError(String value, String message) {
    return value.trim().isEmpty ? message : null;
  }

  String? _priceError(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return 'Enter a whole DZD amount.';
    }

    return null;
  }

  int? _parsePrice(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : int.parse(trimmed);
  }
}
