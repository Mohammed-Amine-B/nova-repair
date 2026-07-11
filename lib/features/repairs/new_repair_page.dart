import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/bottom_action_bar.dart';
import '../../app/widgets/buttons/app_buttons.dart';
import '../../app/widgets/page_header.dart';
import 'domain/entities/repair.dart';
import 'domain/repair_status.dart';
import 'presentation/repair_form_content.dart';
import 'presentation/new_repair_controller.dart';
import 'presentation/new_repair_state.dart';

class NewRepairPage extends ConsumerStatefulWidget {
  const NewRepairPage({
    required this.onCancel,
    required this.onRepairCreated,
    required this.onRepairCreatedForPrint,
    super.key,
  });

  final VoidCallback onCancel;
  final ValueChanged<Repair> onRepairCreated;
  final ValueChanged<Repair> onRepairCreatedForPrint;

  @override
  ConsumerState<NewRepairPage> createState() => _NewRepairPageState();
}

class _NewRepairPageState extends ConsumerState<NewRepairPage> {
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
    final state = ref.watch(newRepairControllerProvider);
    final controller = ref.read(newRepairControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeader(
                  title: 'New Repair',
                  subtitle: 'Create a new repair job',
                ),
                const SizedBox(height: AppSpacing.xl),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: RepairFormContent(
                          controllers: _formControllers,
                          status: RepairStatus.received,
                          statusTitle: 'Initial Status',
                          fieldKeyPrefix: 'new-repair',
                          enabled: !state.isSubmitting,
                          deviceTypeError: state.deviceTypeError,
                          reportedProblemError: state.reportedProblemError,
                          priceError: state.priceError,
                          onDeviceTypeChanged: controller.validateDeviceType,
                          onReportedProblemChanged:
                              controller.validateReportedProblem,
                          onPriceChanged: controller.validatePrice,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (state.submissionError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              0,
              AppSpacing.xxl,
              AppSpacing.sm,
            ),
            child: _SubmissionError(message: state.submissionError!),
          ),
        BottomActionBar(
          leftActions: [
            GhostButton(
              label: 'Cancel',
              icon: Icons.close,
              onPressed: state.isSubmitting ? null : widget.onCancel,
            ),
          ],
          actions: [
            SecondaryButton(
              label: 'Save Repair',
              icon: Icons.save_outlined,
              isLoading: state.activeSubmitAction == NewRepairSubmitAction.save,
              onPressed: state.isSubmitting
                  ? null
                  : () => _submit(NewRepairSubmitAction.save),
            ),
            PrimaryButton(
              label: 'Save & Print',
              icon: Icons.print_outlined,
              isLoading:
                  state.activeSubmitAction ==
                  NewRepairSubmitAction.saveAndPrint,
              onPressed: state.isSubmitting
                  ? null
                  : () => _submit(NewRepairSubmitAction.saveAndPrint),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _submit(NewRepairSubmitAction action) async {
    final repair = await ref
        .read(newRepairControllerProvider.notifier)
        .submit(
          action: action,
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

    if (!mounted || repair == null) {
      return;
    }

    switch (action) {
      case NewRepairSubmitAction.save:
        widget.onRepairCreated(repair);
      case NewRepairSubmitAction.saveAndPrint:
        widget.onRepairCreatedForPrint(repair);
    }
  }
}

class _SubmissionError extends StatelessWidget {
  const _SubmissionError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        border: Border.all(color: AppColors.danger),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
