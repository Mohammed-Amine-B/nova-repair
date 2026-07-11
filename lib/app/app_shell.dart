import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../database/database_provider.dart';
import '../features/backup/backup_restore_page.dart';
import '../features/backup/presentation/backup_restore_controller.dart';
import '../features/backup/presentation/backup_restore_state.dart';
import '../features/backup/restore_confirmation_dialog.dart';
import '../features/common_problems/common_problems_page.dart';
import '../features/common_problems/common_problem_providers.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/dashboard/presentation/dashboard_controller.dart';
import '../features/online_tracking/online_tracking_providers.dart';
import '../features/online_tracking/online_tracking_settings_page.dart';
import '../features/online_tracking/application/tracking_sync_coordinator.dart';
import '../features/online_tracking/presentation/online_tracking_connection_controller.dart';
import '../features/online_tracking/tracking_publisher_providers.dart';
import '../features/printing/presentation/print_preview_controller.dart';
import '../features/printing/presentation/print_document_mode.dart';
import '../features/printing/presentation/print_preview_page.dart';
import '../features/repairs/change_status_dialog.dart';
import '../features/repairs/domain/entities/repair.dart';
import '../features/repairs/edit_repair_page.dart';
import '../features/repairs/new_repair_page.dart';
import '../features/repairs/presentation/edit_repair_controller.dart';
import '../features/repairs/presentation/repair_details_controller.dart';
import '../features/repairs/presentation/repairs_list_controller.dart';
import '../features/repairs/repair_providers.dart';
import '../features/repairs/repair_details_page.dart';
import '../features/repairs/repairs_page.dart';
import '../features/settings/domain/entities/shop_settings.dart';
import '../features/settings/presentation/settings_controller.dart';
import '../features/settings/settings_providers.dart';
import '../features/settings/settings_page.dart';
import 'navigation/app_destination.dart';
import 'theme/app_colors.dart';
import 'widgets/nova_sidebar.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  AppDestination _selectedDestination = AppDestination.dashboard;
  bool _isCreatingRepair = false;
  bool _isEditingRepair = false;
  bool _isPrintingRepair = false;
  bool _isManagingBackupRestore = false;
  bool _isManagingCommonProblems = false;
  bool _isManagingOnlineTracking = false;
  PrintDocumentMode _printDocumentMode = PrintDocumentMode.customerTicket;
  int? _selectedRepairId;
  ProviderSubscription<TrackingSyncCoordinator>?
  _trackingSyncCoordinatorSubscription;

  @override
  void initState() {
    super.initState();
    _trackingSyncCoordinatorSubscription = ref
        .listenManual<TrackingSyncCoordinator>(
          trackingSyncCoordinatorProvider,
          (previous, next) {
            if (!identical(previous, next)) {
              previous?.stop();
              next.start();
            }
          },
          fireImmediately: true,
        );
  }

  @override
  void dispose() {
    _trackingSyncCoordinatorSubscription?.close();
    _trackingSyncCoordinatorSubscription = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sidebarSettings = ref.watch(settingsLoadProvider);
    final sidebarShopName = sidebarSettings.maybeWhen(
      data: (settings) => settings.shopName,
      orElse: () => ShopSettings.defaultShopName,
    );
    final sidebarShopSubtitle = sidebarSettings.maybeWhen(
      data: (settings) => settings.shopSubtitle,
      orElse: () => null,
    );

    return Shortcuts(
      shortcuts: {
        const SingleActivator(
          LogicalKeyboardKey.keyT,
          control: true,
          shift: true,
          alt: true,
        ): const _OpenOnlineTrackingSetupIntent(),
      },
      child: Actions(
        actions: {
          _OpenOnlineTrackingSetupIntent:
              CallbackAction<_OpenOnlineTrackingSetupIntent>(
                onInvoke: (_) {
                  _openOnlineTracking();
                  return null;
                },
              ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Row(
              children: [
                NovaSidebar(
                  selectedDestination: _selectedDestination,
                  shopName: sidebarShopName,
                  shopSubtitle: sidebarShopSubtitle,
                  onDestinationSelected: (destination) {
                    setState(() {
                      _selectedDestination = destination;
                      _isCreatingRepair = false;
                      _isEditingRepair = false;
                      _isPrintingRepair = false;
                      _isManagingBackupRestore = false;
                      _isManagingCommonProblems = false;
                      _isManagingOnlineTracking = false;
                      _selectedRepairId = null;
                    });
                  },
                ),
                Expanded(
                  child: ColoredBox(
                    color: AppColors.canvas,
                    child: SafeArea(
                      child: _selectedDestination.page(
                        onViewAllRepairs: () {
                          setState(() {
                            _selectedDestination = AppDestination.repairs;
                            _isCreatingRepair = false;
                            _isEditingRepair = false;
                            _isPrintingRepair = false;
                            _isManagingBackupRestore = false;
                            _isManagingCommonProblems = false;
                            _selectedRepairId = null;
                          });
                        },
                        onNewRepair: () {
                          setState(() {
                            _selectedDestination = AppDestination.repairs;
                            _isCreatingRepair = true;
                            _isEditingRepair = false;
                            _isPrintingRepair = false;
                            _isManagingBackupRestore = false;
                            _isManagingCommonProblems = false;
                            _selectedRepairId = null;
                          });
                        },
                        onCancelNewRepair: () {
                          setState(() {
                            _selectedDestination = AppDestination.repairs;
                            _isCreatingRepair = false;
                            _isEditingRepair = false;
                            _isPrintingRepair = false;
                            _isManagingBackupRestore = false;
                            _isManagingCommonProblems = false;
                            _selectedRepairId = null;
                          });
                        },
                        onRepairCreated: (_) {
                          ref.invalidate(repairsListControllerProvider);
                          setState(() {
                            _selectedDestination = AppDestination.repairs;
                            _isCreatingRepair = false;
                            _isEditingRepair = false;
                            _isPrintingRepair = false;
                            _isManagingBackupRestore = false;
                            _isManagingCommonProblems = false;
                            _selectedRepairId = null;
                          });
                        },
                        onRepairCreatedForPrint: (repair) {
                          ref.invalidate(repairsListControllerProvider);
                          final repairId = repair.id;
                          setState(() {
                            _selectedDestination = AppDestination.repairs;
                            _isCreatingRepair = false;
                            _isEditingRepair = false;
                            _isPrintingRepair = repairId != null;
                            _isManagingBackupRestore = false;
                            _isManagingCommonProblems = false;
                            _printDocumentMode =
                                PrintDocumentMode.customerTicket;
                            _selectedRepairId = repairId;
                          });
                        },
                        onRepairSelected: _showRepairDetails,
                        onBackToRepairs: () {
                          setState(() {
                            _selectedDestination = AppDestination.repairs;
                            _isCreatingRepair = false;
                            _isEditingRepair = false;
                            _isPrintingRepair = false;
                            _isManagingBackupRestore = false;
                            _isManagingCommonProblems = false;
                            _selectedRepairId = null;
                          });
                        },
                        onCancelEditRepair: () {
                          setState(() {
                            _selectedDestination = AppDestination.repairs;
                            _isCreatingRepair = false;
                            _isEditingRepair = false;
                            _isPrintingRepair = false;
                            _isManagingBackupRestore = false;
                            _isManagingCommonProblems = false;
                          });
                        },
                        onEditRepair: _showEditRepair,
                        onRepairUpdated: _handleRepairUpdated,
                        onChangeStatus: _showChangeStatusDialog,
                        onPrintRepair: _showPrintPreview,
                        onBackFromPrintPreview: () {
                          setState(() {
                            _selectedDestination = AppDestination.repairs;
                            _isCreatingRepair = false;
                            _isEditingRepair = false;
                            _isPrintingRepair = false;
                            _isManagingBackupRestore = false;
                            _isManagingCommonProblems = false;
                          });
                        },
                        onOpenBackupRestore: _openBackupRestore,
                        onOpenCommonProblems: _openCommonProblems,
                        onBackToSettings: _backToSettings,
                        onRestoreRequested: _handleRestoreRequested,
                        selectedRepairId: _selectedRepairId,
                        isCreatingRepair: _isCreatingRepair,
                        isEditingRepair: _isEditingRepair,
                        isPrintingRepair: _isPrintingRepair,
                        isManagingBackupRestore: _isManagingBackupRestore,
                        isManagingCommonProblems: _isManagingCommonProblems,
                        isManagingOnlineTracking: _isManagingOnlineTracking,
                        printDocumentMode: _printDocumentMode,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRepairDetails(Repair repair) {
    final repairId = repair.id;
    if (repairId == null) {
      return;
    }

    setState(() {
      _selectedDestination = AppDestination.repairs;
      _isCreatingRepair = false;
      _isEditingRepair = false;
      _isPrintingRepair = false;
      _isManagingBackupRestore = false;
      _isManagingCommonProblems = false;
      _selectedRepairId = repairId;
    });
  }

  void _showEditRepair(Repair repair) {
    final repairId = repair.id;
    if (repairId == null) {
      return;
    }

    setState(() {
      _selectedDestination = AppDestination.repairs;
      _isCreatingRepair = false;
      _isEditingRepair = true;
      _isPrintingRepair = false;
      _isManagingBackupRestore = false;
      _isManagingCommonProblems = false;
      _selectedRepairId = repairId;
    });
  }

  void _showPrintPreview(Repair repair) {
    final repairId = repair.id;
    if (repairId == null) {
      return;
    }

    setState(() {
      _selectedDestination = AppDestination.repairs;
      _isCreatingRepair = false;
      _isEditingRepair = false;
      _isPrintingRepair = true;
      _isManagingBackupRestore = false;
      _isManagingCommonProblems = false;
      _printDocumentMode = PrintDocumentMode.customerTicket;
      _selectedRepairId = repairId;
    });
  }

  void _handleRepairUpdated(Repair repair) {
    final repairId = repair.id;
    if (repairId != null) {
      ref.invalidate(editRepairLoadProvider(repairId));
      ref.invalidate(editRepairControllerProvider(repairId));
      ref.invalidate(repairDetailsControllerProvider(repairId));
    }
    ref.invalidate(repairsListControllerProvider);
    ref.invalidate(dashboardControllerProvider);

    setState(() {
      _selectedDestination = AppDestination.repairs;
      _isCreatingRepair = false;
      _isEditingRepair = false;
      _isPrintingRepair = false;
      _isManagingBackupRestore = false;
      _isManagingCommonProblems = false;
      _selectedRepairId = repairId ?? _selectedRepairId;
    });
  }

  Future<void> _showChangeStatusDialog(Repair repair) async {
    final updatedRepair = await showChangeStatusDialog(
      context: context,
      repair: repair,
    );

    if (updatedRepair == null || !mounted) {
      return;
    }

    final repairId = updatedRepair.id;
    if (repairId != null) {
      ref.invalidate(repairDetailsControllerProvider(repairId));
    }
    ref.invalidate(repairsListControllerProvider);
    ref.invalidate(dashboardControllerProvider);
  }

  void _openBackupRestore() {
    setState(() {
      _selectedDestination = AppDestination.settings;
      _isCreatingRepair = false;
      _isEditingRepair = false;
      _isPrintingRepair = false;
      _isManagingBackupRestore = true;
      _isManagingCommonProblems = false;
      _isManagingOnlineTracking = false;
      _selectedRepairId = null;
    });
  }

  void _openCommonProblems() {
    setState(() {
      _selectedDestination = AppDestination.settings;
      _isCreatingRepair = false;
      _isEditingRepair = false;
      _isPrintingRepair = false;
      _isManagingBackupRestore = false;
      _isManagingCommonProblems = true;
      _isManagingOnlineTracking = false;
      _selectedRepairId = null;
    });
  }

  void _openOnlineTracking() {
    setState(() {
      _selectedDestination = AppDestination.settings;
      _isCreatingRepair = false;
      _isEditingRepair = false;
      _isPrintingRepair = false;
      _isManagingBackupRestore = false;
      _isManagingCommonProblems = false;
      _isManagingOnlineTracking = true;
      _selectedRepairId = null;
    });
  }

  void _backToSettings() {
    setState(() {
      _selectedDestination = AppDestination.settings;
      _isManagingBackupRestore = false;
      _isManagingCommonProblems = false;
      _isManagingOnlineTracking = false;
    });
  }

  Future<void> _handleRestoreRequested(SelectedBackupFile backup) async {
    final restored = await showRestoreConfirmationDialog(
      context: context,
      backup: backup,
    );
    if (!restored || !mounted) {
      return;
    }

    ref
        .read(backupRestoreControllerProvider.notifier)
        .clearSelectedBackupAfterRestore();
    _invalidateRestoredDatabaseState();

    setState(() {
      _selectedDestination = AppDestination.settings;
      _isCreatingRepair = false;
      _isEditingRepair = false;
      _isPrintingRepair = false;
      _isManagingBackupRestore = true;
      _isManagingCommonProblems = false;
      _isManagingOnlineTracking = false;
      _selectedRepairId = null;
    });
  }

  void _invalidateRestoredDatabaseState() {
    final repairId = _selectedRepairId;

    ref.invalidate(appDatabaseProvider);
    ref.invalidate(repairLocalDataSourceProvider);
    ref.invalidate(repairCodeSequenceLocalDataSourceProvider);
    ref.invalidate(repairRepositoryProvider);
    ref.invalidate(shopSettingsLocalDataSourceProvider);
    ref.invalidate(shopSettingsRepositoryProvider);
    ref.invalidate(commonProblemLocalDataSourceProvider);
    ref.invalidate(commonProblemRepositoryProvider);
    ref.invalidate(trackingSyncOutboxLocalDataSourceProvider);
    ref.invalidate(trackingSyncOutboxRepositoryProvider);
    ref.invalidate(trackingTokenGeneratorProvider);
    ref.invalidate(publicShopIdGeneratorProvider);
    ref.invalidate(installationCredentialExistsProvider);
    ref.invalidate(onlineTrackingConnectionControllerProvider);
    ref.invalidate(trackingSyncCoordinatorProvider);
    ref.invalidate(settingsLoadProvider);
    ref.invalidate(settingsControllerProvider);
    ref.invalidate(dashboardControllerProvider);
    ref.invalidate(repairsListControllerProvider);
    ref.invalidate(backupDataSummaryProvider);

    if (repairId != null) {
      ref.invalidate(repairDetailsControllerProvider(repairId));
      ref.invalidate(editRepairLoadProvider(repairId));
      ref.invalidate(editRepairControllerProvider(repairId));
      ref.invalidate(printPreviewDataProvider(repairId));
    }
  }
}

class _OpenOnlineTrackingSetupIntent extends Intent {
  const _OpenOnlineTrackingSetupIntent();
}

extension on AppDestination {
  Widget page({
    VoidCallback? onViewAllRepairs,
    VoidCallback? onNewRepair,
    VoidCallback? onCancelNewRepair,
    VoidCallback? onCancelEditRepair,
    VoidCallback? onBackToRepairs,
    ValueChanged<Repair>? onRepairCreated,
    ValueChanged<Repair>? onRepairCreatedForPrint,
    ValueChanged<Repair>? onRepairSelected,
    ValueChanged<Repair>? onEditRepair,
    ValueChanged<Repair>? onRepairUpdated,
    ValueChanged<Repair>? onChangeStatus,
    ValueChanged<Repair>? onPrintRepair,
    VoidCallback? onBackFromPrintPreview,
    VoidCallback? onOpenBackupRestore,
    VoidCallback? onOpenCommonProblems,
    VoidCallback? onBackToSettings,
    ValueChanged<SelectedBackupFile>? onRestoreRequested,
    int? selectedRepairId,
    bool isCreatingRepair = false,
    bool isEditingRepair = false,
    bool isPrintingRepair = false,
    bool isManagingBackupRestore = false,
    bool isManagingCommonProblems = false,
    bool isManagingOnlineTracking = false,
    PrintDocumentMode printDocumentMode = PrintDocumentMode.customerTicket,
  }) {
    return switch (this) {
      AppDestination.dashboard => DashboardPage(
        onViewAllRepairs: onViewAllRepairs,
        onRepairSelected: onRepairSelected,
      ),
      AppDestination.repairs =>
        selectedRepairId != null
            ? isPrintingRepair
                  ? PrintPreviewPage(
                      repairId: selectedRepairId,
                      initialMode: printDocumentMode,
                      onBack: onBackFromPrintPreview ?? () {},
                    )
                  : isEditingRepair
                  ? EditRepairPage(
                      repairId: selectedRepairId,
                      onCancel: onCancelEditRepair ?? () {},
                      onBackToRepairs: onBackToRepairs ?? () {},
                      onRepairUpdated: onRepairUpdated ?? (_) {},
                    )
                  : RepairDetailsPage(
                      repairId: selectedRepairId,
                      onBackToRepairs: onBackToRepairs ?? () {},
                      onEditRepair: onEditRepair ?? (_) {},
                      onChangeStatus: onChangeStatus ?? (_) {},
                      onPrintRepair: onPrintRepair ?? (_) {},
                      onCreateWarrantyReturn: (_) {},
                    )
            : isCreatingRepair
            ? NewRepairPage(
                onCancel: onCancelNewRepair ?? () {},
                onRepairCreated: onRepairCreated ?? (_) {},
                onRepairCreatedForPrint: onRepairCreatedForPrint ?? (_) {},
              )
            : RepairsPage(
                onNewRepair: onNewRepair,
                onRepairSelected: onRepairSelected,
              ),
      AppDestination.settings =>
        isManagingBackupRestore
            ? BackupRestorePage(
                onBackToSettings: onBackToSettings ?? () {},
                onRestoreRequested: onRestoreRequested ?? (_) {},
              )
            : isManagingCommonProblems
            ? CommonProblemsPage(onBackToSettings: onBackToSettings ?? () {})
            : isManagingOnlineTracking
            ? OnlineTrackingSettingsPage(
                onBackToSettings: onBackToSettings ?? () {},
              )
            : SettingsPage(
                onOpenBackupRestore: onOpenBackupRestore ?? () {},
                onOpenCommonProblems: onOpenCommonProblems ?? () {},
              ),
    };
  }
}
