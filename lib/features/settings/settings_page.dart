import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/buttons/app_buttons.dart';
import '../../app/widgets/form/app_text_field.dart';
import '../../app/widgets/form/form_section.dart';
import '../../app/widgets/page_header.dart';
import '../../app/widgets/section_card.dart';
import '../printing/domain/entities/local_printer.dart';
import 'domain/entities/shop_settings.dart';
import 'presentation/settings_controller.dart';
import 'presentation/settings_state.dart';

const _systemDefaultPrinterSelection = '__nova_repair_system_default__';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({
    required this.onOpenBackupRestore,
    required this.onOpenCommonProblems,
    super.key,
  });

  final VoidCallback onOpenBackupRestore;
  final VoidCallback onOpenCommonProblems;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _shopNameController = TextEditingController();
  final _shopSubtitleController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _addressController = TextEditingController();

  ShopSettings? _currentSettings;
  bool _initializedFromSettings = false;
  String? _customerTicketPrinterId;
  String? _deviceLabelPrinterId;

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopSubtitleController.dispose();
    _phoneNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsLoadProvider);
    final printersAsync = ref.watch(settingsPrintersProvider);
    final controllerState = ref.watch(settingsControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHeader(
                title: 'Settings',
                subtitle: 'Manage shop information and application preferences',
              ),
              const SizedBox(height: AppSpacing.xl),
              settingsAsync.when(
                loading: () => const _SettingsLoadingState(),
                error: (_, _) => _SettingsErrorState(
                  onRetry: () => ref.invalidate(settingsLoadProvider),
                ),
                data: (settings) {
                  _initializeFromSettings(settings);
                  return _SettingsForm(
                    shopNameController: _shopNameController,
                    shopSubtitleController: _shopSubtitleController,
                    phoneNumberController: _phoneNumberController,
                    addressController: _addressController,
                    controllerState: controllerState,
                    printersAsync: printersAsync,
                    selectedCustomerTicketPrinterId: _customerTicketPrinterId,
                    selectedDeviceLabelPrinterId: _deviceLabelPrinterId,
                    onShopNameChanged: (value) => ref
                        .read(settingsControllerProvider.notifier)
                        .validateShopName(value),
                    onEditableFieldChanged: () => ref
                        .read(settingsControllerProvider.notifier)
                        .clearFeedback(),
                    onCustomerTicketPrinterChanged: (value) {
                      setState(() {
                        _customerTicketPrinterId = _selectionToPrinterId(value);
                      });
                      ref
                          .read(settingsControllerProvider.notifier)
                          .clearFeedback();
                    },
                    onDeviceLabelPrinterChanged: (value) {
                      setState(() {
                        _deviceLabelPrinterId = _selectionToPrinterId(value);
                      });
                      ref
                          .read(settingsControllerProvider.notifier)
                          .clearFeedback();
                    },
                    onRetryPrinters: () =>
                        ref.invalidate(settingsPrintersProvider),
                    onOpenBackupRestore: widget.onOpenBackupRestore,
                    onOpenCommonProblems: widget.onOpenCommonProblems,
                    onSave: controllerState.isSaving
                        ? null
                        : () => _saveSettings(settings),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _initializeFromSettings(ShopSettings settings) {
    if (_initializedFromSettings) {
      return;
    }

    _currentSettings = settings;
    _populateControllers(settings);
    _customerTicketPrinterId = settings.defaultCustomerTicketPrinterId;
    _deviceLabelPrinterId = settings.defaultDeviceLabelPrinterId;
    _initializedFromSettings = true;
  }

  void _populateControllers(ShopSettings settings) {
    _shopNameController.text = settings.shopName;
    _shopSubtitleController.text = settings.shopSubtitle ?? '';
    _phoneNumberController.text = settings.phoneNumber ?? '';
    _addressController.text = settings.address ?? '';
  }

  Future<void> _saveSettings(ShopSettings loadedSettings) async {
    final currentSettings = _currentSettings ?? loadedSettings;
    final saved = await ref
        .read(settingsControllerProvider.notifier)
        .save(
          currentSettings: currentSettings,
          shopName: _shopNameController.text,
          shopSubtitle: _shopSubtitleController.text,
          phoneNumber: _phoneNumberController.text,
          address: _addressController.text,
          defaultCustomerTicketPrinterId: _customerTicketPrinterId,
          defaultDeviceLabelPrinterId: _deviceLabelPrinterId,
        );

    if (saved == null || !mounted) {
      return;
    }

    setState(() {
      _currentSettings = saved;
      _populateControllers(saved);
      _customerTicketPrinterId = saved.defaultCustomerTicketPrinterId;
      _deviceLabelPrinterId = saved.defaultDeviceLabelPrinterId;
    });
    ref.invalidate(settingsLoadProvider);
  }
}

class _SettingsForm extends StatelessWidget {
  const _SettingsForm({
    required this.shopNameController,
    required this.shopSubtitleController,
    required this.phoneNumberController,
    required this.addressController,
    required this.controllerState,
    required this.printersAsync,
    required this.selectedCustomerTicketPrinterId,
    required this.selectedDeviceLabelPrinterId,
    required this.onShopNameChanged,
    required this.onEditableFieldChanged,
    required this.onCustomerTicketPrinterChanged,
    required this.onDeviceLabelPrinterChanged,
    required this.onRetryPrinters,
    required this.onOpenBackupRestore,
    required this.onOpenCommonProblems,
    required this.onSave,
  });

  final TextEditingController shopNameController;
  final TextEditingController shopSubtitleController;
  final TextEditingController phoneNumberController;
  final TextEditingController addressController;
  final SettingsState controllerState;
  final AsyncValue<List<LocalPrinter>> printersAsync;
  final String? selectedCustomerTicketPrinterId;
  final String? selectedDeviceLabelPrinterId;
  final ValueChanged<String> onShopNameChanged;
  final VoidCallback onEditableFieldChanged;
  final ValueChanged<String?> onCustomerTicketPrinterChanged;
  final ValueChanged<String?> onDeviceLabelPrinterChanged;
  final VoidCallback onRetryPrinters;
  final VoidCallback onOpenBackupRestore;
  final VoidCallback onOpenCommonProblems;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (controllerState.saveSuccessMessage != null) ...[
          _SettingsMessageBanner.success(controllerState.saveSuccessMessage!),
          const SizedBox(height: AppSpacing.md),
        ],
        if (controllerState.saveErrorMessage != null) ...[
          _SettingsMessageBanner.error(controllerState.saveErrorMessage!),
          const SizedBox(height: AppSpacing.md),
        ],
        _ShopInformationSection(
          shopNameController: shopNameController,
          shopSubtitleController: shopSubtitleController,
          phoneNumberController: phoneNumberController,
          addressController: addressController,
          shopNameError: controllerState.shopNameError,
          onShopNameChanged: onShopNameChanged,
          onEditableFieldChanged: onEditableFieldChanged,
        ),
        const SizedBox(height: AppSpacing.xl),
        _PrintingDefaultsSection(
          printersAsync: printersAsync,
          selectedCustomerTicketPrinterId: selectedCustomerTicketPrinterId,
          selectedDeviceLabelPrinterId: selectedDeviceLabelPrinterId,
          onCustomerTicketPrinterChanged: onCustomerTicketPrinterChanged,
          onDeviceLabelPrinterChanged: onDeviceLabelPrinterChanged,
          onRetryPrinters: onRetryPrinters,
        ),
        const SizedBox(height: AppSpacing.xl),
        _DataSection(
          onOpenBackupRestore: onOpenBackupRestore,
          onOpenCommonProblems: onOpenCommonProblems,
        ),
        const SizedBox(height: AppSpacing.xl),
        const Divider(color: AppColors.border),
        const SizedBox(height: AppSpacing.xl),
        Align(
          alignment: Alignment.centerRight,
          child: PrimaryButton(
            key: const Key('settings-save-button'),
            label: 'Save Changes',
            onPressed: onSave,
            isLoading: controllerState.isSaving,
          ),
        ),
      ],
    );
  }
}

class _ShopInformationSection extends StatelessWidget {
  const _ShopInformationSection({
    required this.shopNameController,
    required this.shopSubtitleController,
    required this.phoneNumberController,
    required this.addressController,
    required this.shopNameError,
    required this.onShopNameChanged,
    required this.onEditableFieldChanged,
  });

  final TextEditingController shopNameController;
  final TextEditingController shopSubtitleController;
  final TextEditingController phoneNumberController;
  final TextEditingController addressController;
  final String? shopNameError;
  final ValueChanged<String> onShopNameChanged;
  final VoidCallback onEditableFieldChanged;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Shop Information',
      description: 'Information shown on printed customer tickets',
      child: _ResponsiveFieldGrid(
        children: [
          AppTextField(
            key: const Key('settings-shop-name-field'),
            label: 'Shop Name',
            controller: shopNameController,
            errorText: shopNameError,
            onChanged: onShopNameChanged,
          ),
          AppTextField(
            key: const Key('settings-shop-subtitle-field'),
            label: 'Shop Subtitle',
            controller: shopSubtitleController,
            onChanged: (_) => onEditableFieldChanged(),
          ),
          AppTextField(
            key: const Key('settings-phone-number-field'),
            label: 'Phone Number',
            controller: phoneNumberController,
            keyboardType: TextInputType.phone,
            onChanged: (_) => onEditableFieldChanged(),
          ),
          AppTextField(
            key: const Key('settings-address-field'),
            label: 'Address',
            controller: addressController,
            onChanged: (_) => onEditableFieldChanged(),
          ),
        ],
      ),
    );
  }
}

class _PrintingDefaultsSection extends StatelessWidget {
  const _PrintingDefaultsSection({
    required this.printersAsync,
    required this.selectedCustomerTicketPrinterId,
    required this.selectedDeviceLabelPrinterId,
    required this.onCustomerTicketPrinterChanged,
    required this.onDeviceLabelPrinterChanged,
    required this.onRetryPrinters,
  });

  final AsyncValue<List<LocalPrinter>> printersAsync;
  final String? selectedCustomerTicketPrinterId;
  final String? selectedDeviceLabelPrinterId;
  final ValueChanged<String?> onCustomerTicketPrinterChanged;
  final ValueChanged<String?> onDeviceLabelPrinterChanged;
  final VoidCallback onRetryPrinters;

  @override
  Widget build(BuildContext context) {
    final printers = printersAsync.hasValue
        ? printersAsync.requireValue
        : const <LocalPrinter>[];
    final isLoading = printersAsync.isLoading;
    final hasError = printersAsync.hasError;

    return FormSection(
      title: 'Printing Defaults',
      description: 'Choose the default printers used for repair documents',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResponsiveFieldGrid(
            children: [
              _PrinterDropdown(
                key: const Key('settings-customer-ticket-printer-dropdown'),
                label: 'Customer Ticket Printer',
                helperText: 'Used for customer repair tickets',
                selectedPrinterId: selectedCustomerTicketPrinterId,
                printers: printers,
                onChanged: onCustomerTicketPrinterChanged,
              ),
              _PrinterDropdown(
                key: const Key('settings-device-label-printer-dropdown'),
                label: 'Device Label Printer',
                helperText: 'Used for small device labels',
                selectedPrinterId: selectedDeviceLabelPrinterId,
                printers: printers,
                onChanged: onDeviceLabelPrinterChanged,
              ),
            ],
          ),
          if (isLoading) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Loading printers...',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (hasError) ...[
            const SizedBox(height: AppSpacing.md),
            _PrinterDiscoveryError(onRetry: onRetryPrinters),
          ],
        ],
      ),
    );
  }
}

class _PrinterDropdown extends StatelessWidget {
  const _PrinterDropdown({
    required this.label,
    required this.helperText,
    required this.selectedPrinterId,
    required this.printers,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String helperText;
  final String? selectedPrinterId;
  final List<LocalPrinter> printers;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = _printerSelectionItems(
      selectedPrinterId: selectedPrinterId,
      printers: printers,
    );
    final selectedValue = selectedPrinterId ?? _systemDefaultPrinterSelection;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        DropdownButtonFormField<String>(
          initialValue: selectedValue,
          isExpanded: true,
          decoration: const InputDecoration(contentPadding: EdgeInsets.all(12)),
          items: [
            for (final item in items)
              DropdownMenuItem<String>(
                value: item.value,
                child: Text(
                  item.label,
                  overflow: TextOverflow.ellipsis,
                  style: item.isUnavailable
                      ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        )
                      : null,
                ),
              ),
          ],
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          helperText,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  List<_PrinterSelectionItem> _printerSelectionItems({
    required String? selectedPrinterId,
    required List<LocalPrinter> printers,
  }) {
    final items = <_PrinterSelectionItem>[
      const _PrinterSelectionItem(
        value: _systemDefaultPrinterSelection,
        label: 'Default Printer',
      ),
    ];
    final seenPrinterIds = <String>{};

    for (final printer in printers) {
      if (!seenPrinterIds.add(printer.id)) {
        continue;
      }
      items.add(
        _PrinterSelectionItem(value: printer.id, label: printer.displayName),
      );
    }

    if (selectedPrinterId != null &&
        !seenPrinterIds.contains(selectedPrinterId)) {
      items.add(
        _PrinterSelectionItem(
          value: selectedPrinterId,
          label: 'Unavailable printer ($selectedPrinterId)',
          isUnavailable: true,
        ),
      );
    }

    return items;
  }
}

class _PrinterSelectionItem {
  const _PrinterSelectionItem({
    required this.value,
    required this.label,
    this.isUnavailable = false,
  });

  final String value;
  final String label;
  final bool isUnavailable;
}

class _PrinterDiscoveryError extends StatelessWidget {
  const _PrinterDiscoveryError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.dangerSoft,
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Printers could not be loaded. Saved printer preferences are preserved.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SecondaryButton(label: 'Retry', onPressed: onRetry),
        ],
      ),
    );
  }
}

class _DataSection extends StatelessWidget {
  const _DataSection({
    required this.onOpenBackupRestore,
    required this.onOpenCommonProblems,
  });

  final VoidCallback onOpenBackupRestore;
  final VoidCallback onOpenCommonProblems;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Data',
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          _SettingsNavigationCard(
            key: const Key('settings-common-problems-card'),
            icon: Icons.rule_folder_outlined,
            title: 'Common Problems',
            description: 'Manage frequently used repair problems',
            onTap: onOpenCommonProblems,
          ),
          const Divider(height: 1, color: AppColors.border),
          _SettingsNavigationCard(
            key: const Key('settings-backup-restore-card'),
            icon: Icons.backup_outlined,
            title: 'Backup & Restore',
            description: 'Create backups and restore Nova Repair data',
            onTap: onOpenBackupRestore,
          ),
        ],
      ),
    );
  }
}

class _SettingsNavigationCard extends StatelessWidget {
  const _SettingsNavigationCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResponsiveFieldGrid extends StatelessWidget {
  const _ResponsiveFieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) const SizedBox(height: AppSpacing.md),
                children[index],
              ],
            ],
          );
        }

        return Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.xl,
          children: [
            for (final child in children)
              SizedBox(
                width: (constraints.maxWidth - AppSpacing.xl) / 2,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _SettingsLoadingState extends StatelessWidget {
  const _SettingsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      child: SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _SettingsErrorState extends StatelessWidget {
  const _SettingsErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings could not be loaded',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Check the local database and try again.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(label: 'Retry', onPressed: onRetry),
        ],
      ),
    );
  }
}

class _SettingsMessageBanner extends StatelessWidget {
  const _SettingsMessageBanner._({
    required this.message,
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  factory _SettingsMessageBanner.success(String message) {
    return _SettingsMessageBanner._(
      message: message,
      background: const Color(0xFFF0FDF4),
      border: const Color(0xFFBBF7D0),
      foreground: AppColors.success,
      icon: Icons.check_circle_outline,
    );
  }

  factory _SettingsMessageBanner.error(String message) {
    return _SettingsMessageBanner._(
      message: message,
      background: AppColors.dangerSoft,
      border: const Color(0xFFFECACA),
      foreground: AppColors.danger,
      icon: Icons.error_outline,
    );
  }

  final String message;
  final Color background;
  final Color border;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

String? _selectionToPrinterId(String? value) {
  return value == null || value == _systemDefaultPrinterSelection
      ? null
      : value;
}
