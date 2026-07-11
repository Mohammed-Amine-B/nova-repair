import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/clear_repair_price_input.dart';
import '../domain/entities/propose_repair_price_input.dart';
import '../domain/entities/repair.dart';
import '../domain/entities/update_repair_input.dart';
import '../domain/repair_status.dart';
import '../repair_providers.dart';
import 'edit_repair_state.dart';

final editRepairLoadProvider = FutureProvider.autoDispose.family<Repair?, int>((
  ref,
  repairId,
) {
  return ref.watch(repairRepositoryProvider).getRepairById(repairId);
});

final editRepairControllerProvider = NotifierProvider.autoDispose
    .family<EditRepairController, EditRepairState, int>(
      EditRepairController.new,
    );

class EditRepairController extends Notifier<EditRepairState> {
  EditRepairController(this.repairId);

  final int repairId;

  @override
  EditRepairState build() {
    return const EditRepairState();
  }

  static bool canEditPriceForStatus(RepairStatus status) {
    return status == RepairStatus.diagnosing ||
        status == RepairStatus.waitingForCustomerApproval;
  }

  void validateDeviceType(String value) {
    final error = _requiredTextError(value, 'Device type is required.');
    state = state.copyWith(
      deviceTypeError: error,
      clearDeviceTypeError: error == null,
      clearSubmissionError: true,
      clearPartialFailure: true,
      clearLatestRepairAfterPartialFailure: true,
    );
  }

  void validateReportedProblem(String value) {
    final error = _requiredTextError(value, 'Reported problem is required.');
    state = state.copyWith(
      reportedProblemError: error,
      clearReportedProblemError: error == null,
      clearSubmissionError: true,
      clearPartialFailure: true,
      clearLatestRepairAfterPartialFailure: true,
    );
  }

  void validatePrice(String value) {
    final error = _priceError(value);
    state = state.copyWith(
      priceError: error,
      clearPriceError: error == null,
      clearSubmissionError: true,
      clearPartialFailure: true,
      clearLatestRepairAfterPartialFailure: true,
    );
  }

  Future<Repair?> submit({
    required Repair originalRepair,
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

    final priceEditable = canEditPriceForStatus(originalRepair.status);
    final deviceTypeError = _requiredTextError(
      deviceType,
      'Device type is required.',
    );
    final reportedProblemError = _requiredTextError(
      reportedProblem,
      'Reported problem is required.',
    );
    final priceError = priceEditable ? _priceError(priceText) : null;

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
        clearPartialFailure: true,
        clearLatestRepairAfterPartialFailure: true,
      );
      return null;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearSubmissionError: true,
      clearPartialFailure: true,
      clearLatestRepairAfterPartialFailure: true,
    );

    try {
      var latestRepair = await ref
          .read(updateRepairUseCaseProvider)
          .call(
            UpdateRepairInput(
              repairId: repairId,
              customerName: customerName,
              customerPhone: customerPhone,
              deviceType: deviceType,
              brand: brand,
              model: model,
              reportedProblem: reportedProblem,
              receivedAccessories: receivedAccessories,
              deviceAccessInfo: deviceAccessInfo,
              internalNotes: internalNotes,
              customerMessage: customerMessage,
            ),
          );

      if (priceEditable) {
        try {
          latestRepair = await _applyPriceChangeIfNeeded(
            originalRepair: originalRepair,
            editedPrice: _parsePrice(priceText),
          );
        } catch (_) {
          final reloaded = await ref
              .read(repairRepositoryProvider)
              .getRepairById(repairId);
          state = state.copyWith(
            isSubmitting: false,
            partialFailureMessage:
                'Repair information was updated, but the price could not be changed. Review the current values and try again.',
            latestRepairAfterPartialFailure: reloaded ?? latestRepair,
          );
          return null;
        }
      }

      state = state.copyWith(isSubmitting: false);
      return latestRepair;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        submissionError: 'Repair could not be updated. Please try again.',
      );
      return null;
    }
  }

  Future<Repair> _applyPriceChangeIfNeeded({
    required Repair originalRepair,
    required int? editedPrice,
  }) {
    final originalPrice = originalRepair.priceAmount;

    if (originalPrice == editedPrice) {
      return ref.read(repairRepositoryProvider).getRepairById(repairId).then((
        repair,
      ) {
        if (repair == null) {
          throw StateError('Updated repair could not be loaded.');
        }
        return repair;
      });
    }

    if (editedPrice == null) {
      return ref
          .read(clearRepairPriceUseCaseProvider)
          .call(ClearRepairPriceInput(repairId: repairId));
    }

    return ref
        .read(proposeRepairPriceUseCaseProvider)
        .call(
          ProposeRepairPriceInput(repairId: repairId, priceAmount: editedPrice),
        );
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
