import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/change_repair_status_input.dart';
import '../domain/entities/repair.dart';
import '../domain/errors/repair_status_workflow_exception.dart';
import '../domain/repair_status.dart';
import '../domain/services/repair_status_transition_policy.dart';
import '../repair_providers.dart';
import 'change_status_dialog_state.dart';

final changeStatusDialogControllerProvider = NotifierProvider.autoDispose
    .family<ChangeStatusDialogController, ChangeStatusDialogState, Repair>(
      ChangeStatusDialogController.new,
    );

class ChangeStatusDialogController extends Notifier<ChangeStatusDialogState> {
  ChangeStatusDialogController(this.repair);

  final Repair repair;
  final RepairStatusTransitionPolicy _transitionPolicy =
      const RepairStatusTransitionPolicy();

  @override
  ChangeStatusDialogState build() {
    return ChangeStatusDialogState(
      repair: repair,
      customerMessageText: repair.customerMessage ?? '',
    );
  }

  List<RepairStatus> allowedTargets() {
    return _transitionPolicy.allowedNextStatuses(state.repair.status);
  }

  bool isSelectable(RepairStatus status) {
    return status != state.repair.status &&
        _transitionPolicy.canTransition(from: state.repair.status, to: status);
  }

  void selectStatus(RepairStatus status) {
    if (state.isSubmitting || !isSelectable(status)) {
      return;
    }

    state = state.copyWith(selectedStatus: status, clearSubmissionError: true);
  }

  void updateCustomerMessage(String value) {
    state = state.copyWith(
      customerMessageText: value,
      customerMessageChanged: true,
      clearSubmissionError: true,
    );
  }

  Future<Repair?> submit() async {
    if (!state.canSubmit) {
      return null;
    }

    final targetStatus = state.selectedStatus;
    final repairId = state.repair.id;

    if (targetStatus == null || repairId == null) {
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearSubmissionError: true);

    try {
      final updatedRepair = await ref
          .read(changeRepairStatusUseCaseProvider)
          .call(
            ChangeRepairStatusInput(
              repairId: repairId,
              targetStatus: targetStatus,
              customerMessage: state.customerMessageChanged
                  ? OptionalCustomerMessage.replace(state.customerMessageText)
                  : const OptionalCustomerMessage.unchanged(),
            ),
          );

      state = state.copyWith(isSubmitting: false);
      return updatedRepair;
    } on InvalidRepairStatusTransitionException {
      state = state.copyWith(
        isSubmitting: false,
        submissionError:
            'This status change is no longer allowed. Refresh and try again.',
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        submissionError: 'Status could not be updated. Please try again.',
      );
      return null;
    }
  }
}
