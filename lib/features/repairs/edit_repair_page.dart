import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/bottom_action_bar.dart';
import '../../app/widgets/buttons/app_buttons.dart';
import '../../app/widgets/page_header.dart';
import '../../app/widgets/section_card.dart';
import 'domain/entities/repair.dart';
import 'presentation/edit_repair_controller.dart';
import 'presentation/edit_repair_state.dart';
import 'presentation/repair_form_content.dart';

class EditRepairPage extends ConsumerStatefulWidget {
  const EditRepairPage({
    required this.repairId,
    required this.onCancel,
    required this.onBackToRepairs,
    required this.onRepairUpdated,
    super.key,
  });

  final int repairId;
  final VoidCallback onCancel;
  final VoidCallback onBackToRepairs;
  final ValueChanged<Repair> onRepairUpdated;

  @override
  ConsumerState<EditRepairPage> createState() => _EditRepairPageState();
}

class _EditRepairPageState extends ConsumerState<EditRepairPage> {
  late final TextEditingController _customerNameController;
  late final TextEditingController _customerPhoneController;
  late final TextEditingController _deviceTypeController;
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _reportedProblemController;
  late final TextEditingController _receivedAccessoriesController;
  late final TextEditingController _deviceAccessInfoController;
  late final TextEditingController _priceController;
  late final TextEditingController _internalNotesController;
  late final TextEditingController _customerMessageController;
  late final RepairFormControllers _formControllers;

  Repair? _currentRepair;
  DateTime? _lastAppliedUpdatedAt;
  int? _lastAppliedPrice;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController();
    _customerPhoneController = TextEditingController();
    _deviceTypeController = TextEditingController();
    _brandController = TextEditingController();
    _modelController = TextEditingController();
    _reportedProblemController = TextEditingController();
    _receivedAccessoriesController = TextEditingController();
    _deviceAccessInfoController = TextEditingController();
    _priceController = TextEditingController();
    _internalNotesController = TextEditingController();
    _customerMessageController = TextEditingController();
    _formControllers = RepairFormControllers(
      customerName: _customerNameController,
      customerPhone: _customerPhoneController,
      deviceType: _deviceTypeController,
      brand: _brandController,
      model: _modelController,
      reportedProblem: _reportedProblemController,
      receivedAccessories: _receivedAccessoriesController,
      deviceAccessInfo: _deviceAccessInfoController,
      price: _priceController,
      internalNotes: _internalNotesController,
      customerMessage: _customerMessageController,
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _deviceTypeController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _reportedProblemController.dispose();
    _receivedAccessoriesController.dispose();
    _deviceAccessInfoController.dispose();
    _priceController.dispose();
    _internalNotesController.dispose();
    _customerMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loadedRepair = ref.watch(editRepairLoadProvider(widget.repairId));
    final editState = ref.watch(editRepairControllerProvider(widget.repairId));
    final controller = ref.read(
      editRepairControllerProvider(widget.repairId).notifier,
    );

    final partialRepair = editState.latestRepairAfterPartialFailure;
    if (partialRepair != null) {
      _applyRepair(partialRepair);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: loadedRepair.when(
              data: (repair) {
                if (repair == null) {
                  return _EditRepairNotFoundState(
                    onBackToRepairs: widget.onBackToRepairs,
                  );
                }

                _applyRepair(repair);

                return _EditRepairContent(
                  repair: _currentRepair ?? repair,
                  formControllers: _formControllers,
                  state: editState,
                  controller: controller,
                );
              },
              loading: () => const _EditRepairLoadingState(),
              error: (error, stackTrace) => _EditRepairErrorState(
                onRetry: () {
                  ref.invalidate(editRepairLoadProvider(widget.repairId));
                },
                onBackToRepairs: widget.onBackToRepairs,
              ),
            ),
          ),
        ),
        if (editState.submissionError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              0,
              AppSpacing.xxl,
              AppSpacing.sm,
            ),
            child: _SubmissionMessage(
              message: editState.submissionError!,
              isWarning: false,
            ),
          ),
        if (editState.partialFailureMessage != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              0,
              AppSpacing.xxl,
              AppSpacing.sm,
            ),
            child: _SubmissionMessage(
              message: editState.partialFailureMessage!,
              isWarning: true,
            ),
          ),
        BottomActionBar(
          leftActions: [
            GhostButton(
              label: 'Cancel',
              icon: Icons.close,
              onPressed: editState.isSubmitting ? null : widget.onCancel,
            ),
          ],
          actions: [
            PrimaryButton(
              label: 'Save Changes',
              icon: Icons.save_outlined,
              isLoading: editState.isSubmitting,
              onPressed: editState.isSubmitting || _currentRepair == null
                  ? null
                  : _submit,
            ),
          ],
        ),
      ],
    );
  }

  void _applyRepair(Repair repair) {
    final currentRepair = _currentRepair;
    if (currentRepair?.id == repair.id &&
        currentRepair!.updatedAt.isAfter(repair.updatedAt)) {
      return;
    }

    if (_currentRepair?.id == repair.id &&
        _lastAppliedUpdatedAt == repair.updatedAt &&
        _lastAppliedPrice == repair.priceAmount) {
      return;
    }

    _currentRepair = repair;
    _lastAppliedUpdatedAt = repair.updatedAt;
    _lastAppliedPrice = repair.priceAmount;
    _customerNameController.text = repair.customerName ?? '';
    _customerPhoneController.text = repair.customerPhone ?? '';
    _deviceTypeController.text = repair.deviceType ?? '';
    _brandController.text = repair.brand ?? '';
    _modelController.text = repair.model ?? '';
    _reportedProblemController.text = repair.reportedProblem;
    _receivedAccessoriesController.text = repair.receivedAccessories ?? '';
    _deviceAccessInfoController.text = repair.deviceAccessInfo ?? '';
    _priceController.text = repair.priceAmount?.toString() ?? '';
    _internalNotesController.text = repair.internalNotes ?? '';
    _customerMessageController.text = repair.customerMessage ?? '';
  }

  Future<void> _submit() async {
    final originalRepair = _currentRepair;
    if (originalRepair == null) {
      return;
    }

    final updatedRepair = await ref
        .read(editRepairControllerProvider(widget.repairId).notifier)
        .submit(
          originalRepair: originalRepair,
          customerName: _customerNameController.text,
          customerPhone: _customerPhoneController.text,
          deviceType: _deviceTypeController.text,
          brand: _brandController.text,
          model: _modelController.text,
          reportedProblem: _reportedProblemController.text,
          receivedAccessories: _receivedAccessoriesController.text,
          deviceAccessInfo: _deviceAccessInfoController.text,
          priceText: _priceController.text,
          internalNotes: _internalNotesController.text,
          customerMessage: _customerMessageController.text,
        );

    if (!mounted || updatedRepair == null) {
      return;
    }

    setState(() {
      _applyRepair(updatedRepair);
    });
    widget.onRepairUpdated(updatedRepair);
  }
}

class _EditRepairContent extends StatelessWidget {
  const _EditRepairContent({
    required this.repair,
    required this.formControllers,
    required this.state,
    required this.controller,
  });

  final Repair repair;
  final RepairFormControllers formControllers;
  final EditRepairState state;
  final EditRepairController controller;

  @override
  Widget build(BuildContext context) {
    final canEditPrice = EditRepairController.canEditPriceForStatus(
      repair.status,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Edit Repair',
          subtitle: 'Update repair information for ${repair.repairCode}',
        ),
        const SizedBox(height: AppSpacing.xl),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: RepairFormContent(
                  controllers: formControllers,
                  status: repair.status,
                  statusTitle: 'Current Status',
                  fieldKeyPrefix: 'edit-repair',
                  enabled: !state.isSubmitting,
                  priceEnabled: canEditPrice,
                  deviceTypeError: state.deviceTypeError,
                  reportedProblemError: state.reportedProblemError,
                  priceError: state.priceError,
                  onDeviceTypeChanged: controller.validateDeviceType,
                  onReportedProblemChanged: controller.validateReportedProblem,
                  onPriceChanged: controller.validatePrice,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditRepairLoadingState extends StatelessWidget {
  const _EditRepairLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Edit Repair',
          subtitle: 'Loading repair information',
        ),
        SizedBox(height: AppSpacing.xl),
        Expanded(
          child: SectionCard(child: Center(child: CircularProgressIndicator())),
        ),
      ],
    );
  }
}

class _EditRepairNotFoundState extends StatelessWidget {
  const _EditRepairNotFoundState({required this.onBackToRepairs});

  final VoidCallback onBackToRepairs;

  @override
  Widget build(BuildContext context) {
    return _SimpleState(
      title: 'Repair not found',
      message: 'The repair could not be found.',
      action: GhostButton(
        label: 'Back to Repairs',
        icon: Icons.arrow_back,
        onPressed: onBackToRepairs,
      ),
    );
  }
}

class _EditRepairErrorState extends StatelessWidget {
  const _EditRepairErrorState({
    required this.onRetry,
    required this.onBackToRepairs,
  });

  final VoidCallback onRetry;
  final VoidCallback onBackToRepairs;

  @override
  Widget build(BuildContext context) {
    return _SimpleState(
      title: 'Repair could not be loaded',
      message: 'Try again or return to the repairs list.',
      action: Wrap(
        spacing: AppSpacing.xs,
        children: [
          SecondaryButton(
            label: 'Retry',
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
          GhostButton(
            label: 'Back to Repairs',
            icon: Icons.arrow_back,
            onPressed: onBackToRepairs,
          ),
        ],
      ),
    );
  }
}

class _SimpleState extends StatelessWidget {
  const _SimpleState({
    required this.title,
    required this.message,
    required this.action,
  });

  final String title;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeader(
          title: 'Edit Repair',
          subtitle: 'Update repair information',
        ),
        const SizedBox(height: AppSpacing.xl),
        Expanded(
          child: SectionCard(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  action,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmissionMessage extends StatelessWidget {
  const _SubmissionMessage({required this.message, required this.isWarning});

  final String message;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final color = isWarning
        ? AppColors.waitingForCustomerApproval.foreground
        : AppColors.danger;
    final background = isWarning
        ? AppColors.waitingForCustomerApproval.background
        : AppColors.dangerSoft;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              isWarning ? Icons.warning_amber_outlined : Icons.error_outline,
              color: color,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
