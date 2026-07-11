import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/form/app_text_field.dart';
import '../../../app/widgets/form/form_section.dart';
import '../../../app/widgets/status_badge.dart';
import '../domain/repair_status.dart';
import 'common_problem_insertion_controller.dart';
import 'common_problem_picker.dart';

class RepairFormControllers {
  const RepairFormControllers({
    required this.customerName,
    required this.customerPhone,
    required this.deviceType,
    required this.brand,
    required this.model,
    required this.reportedProblem,
    required this.receivedAccessories,
    required this.deviceAccessInfo,
    required this.price,
    required this.internalNotes,
    required this.customerMessage,
  });

  final TextEditingController customerName;
  final TextEditingController customerPhone;
  final TextEditingController deviceType;
  final TextEditingController brand;
  final TextEditingController model;
  final TextEditingController reportedProblem;
  final TextEditingController receivedAccessories;
  final TextEditingController deviceAccessInfo;
  final TextEditingController price;
  final TextEditingController internalNotes;
  final TextEditingController customerMessage;
}

class RepairFormContent extends StatelessWidget {
  const RepairFormContent({
    required this.controllers,
    required this.status,
    required this.statusTitle,
    required this.fieldKeyPrefix,
    this.deviceTypeError,
    this.reportedProblemError,
    this.priceError,
    this.enabled = true,
    this.priceEnabled = true,
    this.priceReadOnlyHelperText =
        'Price can only be changed while diagnosing or waiting for customer approval.',
    this.onDeviceTypeChanged,
    this.onReportedProblemChanged,
    this.onPriceChanged,
    super.key,
  });

  final RepairFormControllers controllers;
  final RepairStatus status;
  final String statusTitle;
  final String fieldKeyPrefix;
  final String? deviceTypeError;
  final String? reportedProblemError;
  final String? priceError;
  final bool enabled;
  final bool priceEnabled;
  final String priceReadOnlyHelperText;
  final ValueChanged<String>? onDeviceTypeChanged;
  final ValueChanged<String>? onReportedProblemChanged;
  final ValueChanged<String>? onPriceChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;
        final left = _RepairFormLeftColumn(
          controllers: controllers,
          fieldKeyPrefix: fieldKeyPrefix,
          enabled: enabled,
          deviceTypeError: deviceTypeError,
          reportedProblemError: reportedProblemError,
          onDeviceTypeChanged: onDeviceTypeChanged,
          onReportedProblemChanged: onReportedProblemChanged,
        );
        final right = _RepairFormRightColumn(
          controllers: controllers,
          fieldKeyPrefix: fieldKeyPrefix,
          enabled: enabled,
          priceEnabled: priceEnabled,
          priceReadOnlyHelperText: priceReadOnlyHelperText,
          status: status,
          statusTitle: statusTitle,
          priceError: priceError,
          onPriceChanged: onPriceChanged,
        );

        if (compact) {
          return Column(
            children: [
              left,
              const SizedBox(height: AppSpacing.lg),
              right,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: left),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

class _RepairFormLeftColumn extends ConsumerWidget {
  const _RepairFormLeftColumn({
    required this.controllers,
    required this.fieldKeyPrefix,
    required this.enabled,
    required this.deviceTypeError,
    required this.reportedProblemError,
    required this.onDeviceTypeChanged,
    required this.onReportedProblemChanged,
  });

  final RepairFormControllers controllers;
  final String fieldKeyPrefix;
  final bool enabled;
  final String? deviceTypeError;
  final String? reportedProblemError;
  final ValueChanged<String>? onDeviceTypeChanged;
  final ValueChanged<String>? onReportedProblemChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insertionState = ref.watch(commonProblemInsertionControllerProvider);

    return Column(
      children: [
        FormSection(
          title: 'Customer Information',
          child: _TwoColumnFields(
            children: [
              AppTextField(
                key: Key('$fieldKeyPrefix-customer-name'),
                label: 'Customer Name',
                placeholder: 'Full name',
                controller: controllers.customerName,
                enabled: enabled,
              ),
              AppTextField(
                key: Key('$fieldKeyPrefix-customer-phone'),
                label: 'Phone Number',
                placeholder: '0555 12 34 56',
                controller: controllers.customerPhone,
                enabled: enabled,
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FormSection(
          title: 'Device Information',
          child: _ThreeColumnFields(
            children: [
              AppTextField(
                key: Key('$fieldKeyPrefix-device-type'),
                label: 'Device Type',
                placeholder: 'Laptop, phone, printer',
                controller: controllers.deviceType,
                enabled: enabled,
                errorText: deviceTypeError,
                onChanged: onDeviceTypeChanged,
              ),
              AppTextField(
                key: Key('$fieldKeyPrefix-brand'),
                label: 'Brand',
                placeholder: 'Apple, Samsung',
                controller: controllers.brand,
                enabled: enabled,
              ),
              AppTextField(
                key: Key('$fieldKeyPrefix-model'),
                label: 'Model',
                placeholder: 'iPhone 15 Pro',
                controller: controllers.model,
                enabled: enabled,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FormSection(
          title: 'Reported Problem',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CommonProblemPicker(
                enabled: enabled && !insertionState.isInserting,
                onProblemSelected: (problem) async {
                  final result = await ref
                      .read(commonProblemInsertionControllerProvider.notifier)
                      .insertProblem(
                        textController: controllers.reportedProblem,
                        problem: problem,
                      );
                  if (result.inserted) {
                    onReportedProblemChanged?.call(
                      controllers.reportedProblem.text,
                    );
                  }
                },
              ),
              if (insertionState.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  insertionState.errorMessage!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppTextArea(
                key: Key('$fieldKeyPrefix-reported-problem'),
                label: 'Reported Problem',
                placeholder: 'Describe the issue reported by the customer',
                controller: controllers.reportedProblem,
                enabled: enabled,
                errorText: reportedProblemError,
                onChanged: (value) {
                  ref
                      .read(commonProblemInsertionControllerProvider.notifier)
                      .clearError();
                  onReportedProblemChanged?.call(value);
                },
                minLines: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FormSection(
          title: 'Notes',
          child: Column(
            children: [
              AppTextArea(
                key: Key('$fieldKeyPrefix-internal-notes'),
                label: 'Internal Notes',
                helperText: 'Internal only',
                placeholder: 'Private notes for the repair shop',
                controller: controllers.internalNotes,
                enabled: enabled,
                minLines: 3,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextArea(
                key: Key('$fieldKeyPrefix-customer-message'),
                label: 'Customer Message',
                helperText:
                    'This may later be shown to the customer in repair tracking',
                placeholder: 'Customer-visible update',
                controller: controllers.customerMessage,
                enabled: enabled,
                minLines: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RepairFormRightColumn extends StatelessWidget {
  const _RepairFormRightColumn({
    required this.controllers,
    required this.fieldKeyPrefix,
    required this.enabled,
    required this.priceEnabled,
    required this.priceReadOnlyHelperText,
    required this.status,
    required this.statusTitle,
    required this.priceError,
    required this.onPriceChanged,
  });

  final RepairFormControllers controllers;
  final String fieldKeyPrefix;
  final bool enabled;
  final bool priceEnabled;
  final String priceReadOnlyHelperText;
  final RepairStatus status;
  final String statusTitle;
  final String? priceError;
  final ValueChanged<String>? onPriceChanged;

  @override
  Widget build(BuildContext context) {
    final priceCanEdit = enabled && priceEnabled;

    return Column(
      children: [
        FormSection(
          title: statusTitle,
          child: Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge(status: status),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FormSection(
          title: 'Received Accessories',
          child: AppTextArea(
            key: Key('$fieldKeyPrefix-received-accessories'),
            label: 'Received Accessories',
            helperText: 'List any accessories received with the device',
            placeholder: 'Charger, cable, bag',
            controller: controllers.receivedAccessories,
            enabled: enabled,
            minLines: 3,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FormSection(
          title: 'Device Access',
          child: AppTextArea(
            key: Key('$fieldKeyPrefix-device-access-info'),
            label: 'PIN / Password / Access Note',
            helperText: 'Internal only — not shown on printed tickets',
            placeholder: 'PIN, password, or pattern description',
            controller: controllers.deviceAccessInfo,
            enabled: enabled,
            minLines: 3,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FormSection(
          title: 'Price',
          child: AppTextField(
            key: Key('$fieldKeyPrefix-price'),
            label: 'Proposed Repair Price',
            helperText: priceCanEdit
                ? 'Optional — can be added later after diagnosis'
                : priceReadOnlyHelperText,
            placeholder: '0',
            controller: controllers.price,
            enabled: enabled,
            readOnly: !priceEnabled,
            keyboardType: TextInputType.number,
            inputFormatters: priceCanEdit
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            errorText: priceError,
            onChanged: priceCanEdit ? onPriceChanged : null,
            suffix: const Center(
              widthFactor: 1,
              child: Padding(
                padding: EdgeInsets.only(right: AppSpacing.sm),
                child: Text('DA'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TwoColumnFields extends StatelessWidget {
  const _TwoColumnFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(
            children: _withVerticalSpacing(children, AppSpacing.md),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _withHorizontalSpacing(children, AppSpacing.md),
        );
      },
    );
  }
}

class _ThreeColumnFields extends StatelessWidget {
  const _ThreeColumnFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: _withVerticalSpacing(children, AppSpacing.md),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _withHorizontalSpacing(children, AppSpacing.md),
        );
      },
    );
  }
}

List<Widget> _withHorizontalSpacing(List<Widget> children, double spacing) {
  return [
    for (var index = 0; index < children.length; index++) ...[
      if (index > 0) SizedBox(width: spacing),
      Expanded(child: children[index]),
    ],
  ];
}

List<Widget> _withVerticalSpacing(List<Widget> children, double spacing) {
  return [
    for (var index = 0; index < children.length; index++) ...[
      if (index > 0) SizedBox(height: spacing),
      children[index],
    ],
  ];
}
