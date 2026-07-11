import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/buttons/app_buttons.dart';
import '../../app/widgets/dialogs/confirmation_dialog.dart';
import '../../app/widgets/form/app_text_field.dart';
import '../../app/widgets/page_header.dart';
import '../../app/widgets/section_card.dart';
import '../settings/presentation/settings_controller.dart';
import 'online_tracking_providers.dart';
import 'presentation/online_tracking_connection_controller.dart';
import 'presentation/online_tracking_connection_state.dart';

class OnlineTrackingSettingsPage extends ConsumerStatefulWidget {
  const OnlineTrackingSettingsPage({required this.onBackToSettings, super.key});

  final VoidCallback onBackToSettings;

  @override
  ConsumerState<OnlineTrackingSettingsPage> createState() =>
      _OnlineTrackingSettingsPageState();
}

class _OnlineTrackingSettingsPageState
    extends ConsumerState<OnlineTrackingSettingsPage> {
  final _secretController = TextEditingController();

  @override
  void dispose() {
    _secretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsLoadProvider);
    final credentialAsync = ref.watch(installationCredentialExistsProvider);
    final state = ref.watch(onlineTrackingConnectionControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GhostButton(
                key: const Key('online-tracking-back-to-settings'),
                label: 'Close',
                icon: Icons.close,
                onPressed: widget.onBackToSettings,
              ),
              const SizedBox(height: AppSpacing.lg),
              const PageHeader(
                title: 'Online Installation Setup',
                subtitle:
                    'Configure secure online tracking credentials for this installation',
              ),
              const SizedBox(height: AppSpacing.xl),
              settingsAsync.when(
                loading: () => const _OnlineTrackingLoadingState(),
                error: (_, _) => _OnlineTrackingErrorState(
                  message: 'Settings could not be loaded.',
                  onRetry: () => ref.invalidate(settingsLoadProvider),
                ),
                data: (settings) {
                  final publicShopId = settings.publicShopId;
                  if (publicShopId == null || publicShopId.isEmpty) {
                    return _OnlineTrackingErrorState(
                      message: 'Public shop ID is not available.',
                      onRetry: () => ref.invalidate(settingsLoadProvider),
                    );
                  }

                  return credentialAsync.when(
                    loading: () => const _OnlineTrackingLoadingState(),
                    error: (_, _) => _OnlineTrackingErrorState(
                      message:
                          'Online tracking credentials could not be read from this device.',
                      onRetry: () =>
                          ref.invalidate(installationCredentialExistsProvider),
                    ),
                    data: (hasCredential) => _OnlineTrackingConnectionContent(
                      publicShopId: publicShopId,
                      hasCredential: hasCredential,
                      secretController: _secretController,
                      state: state,
                      onSecretChanged: (_) => ref
                          .read(
                            onlineTrackingConnectionControllerProvider.notifier,
                          )
                          .clearFeedback(),
                      onConnect: state.isSubmitting
                          ? null
                          : () => _connect(publicShopId),
                      onDisconnect: state.isSubmitting
                          ? null
                          : () => _confirmDisconnect(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _connect(String publicShopId) async {
    final connected = await ref
        .read(onlineTrackingConnectionControllerProvider.notifier)
        .connect(
          publicShopId: publicShopId,
          installationSecret: _secretController.text,
        );

    if (connected) {
      _secretController.clear();
    }
  }

  Future<void> _confirmDisconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return ConfirmationDialog(
          title: 'Remove Online Tracking Credential?',
          message:
              'This device will stop publishing repair tracking updates until a valid credential is configured again.',
          cancelLabel: 'Cancel',
          confirmLabel: 'Remove Credential',
          icon: Icons.link_off,
          destructive: true,
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
          content: Text(
            'Local repairs and pending sync data will not be deleted.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await ref
        .read(onlineTrackingConnectionControllerProvider.notifier)
        .disconnect();
  }
}

class _OnlineTrackingConnectionContent extends StatelessWidget {
  const _OnlineTrackingConnectionContent({
    required this.publicShopId,
    required this.hasCredential,
    required this.secretController,
    required this.state,
    required this.onSecretChanged,
    required this.onConnect,
    required this.onDisconnect,
  });

  final String publicShopId;
  final bool hasCredential;
  final TextEditingController secretController;
  final OnlineTrackingConnectionState state;
  final ValueChanged<String> onSecretChanged;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.successMessage != null) ...[
          _OnlineTrackingBanner.success(state.successMessage!),
          const SizedBox(height: AppSpacing.md),
        ],
        if (state.errorMessage != null) ...[
          _OnlineTrackingBanner.error(state.errorMessage!),
          const SizedBox(height: AppSpacing.md),
        ],
        SectionCard(
          title: 'Connection',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ConnectionStatusBadge(connected: hasCredential),
              const SizedBox(height: AppSpacing.lg),
              _ReadOnlyValue(label: 'Public Shop ID', value: publicShopId),
              const SizedBox(height: AppSpacing.lg),
              if (hasCredential)
                _ConnectedActions(
                  isSubmitting: state.isSubmitting,
                  onDisconnect: onDisconnect,
                )
              else
                _DisconnectedForm(
                  secretController: secretController,
                  errorText: state.secretInputError,
                  isSubmitting: state.isSubmitting,
                  onChanged: onSecretChanged,
                  onConnect: onConnect,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DisconnectedForm extends StatelessWidget {
  const _DisconnectedForm({
    required this.secretController,
    required this.errorText,
    required this.isSubmitting,
    required this.onChanged,
    required this.onConnect,
  });

  final TextEditingController secretController;
  final String? errorText;
  final bool isSubmitting;
  final ValueChanged<String> onChanged;
  final VoidCallback? onConnect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: const Key('online-tracking-installation-secret-field'),
          label: 'Installation Secret',
          placeholder: 'Paste the installation secret',
          helperText:
              'The installation secret is stored securely on this device.',
          controller: secretController,
          errorText: errorText,
          obscureText: true,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.lg),
        Align(
          alignment: Alignment.centerRight,
          child: PrimaryButton(
            key: const Key('online-tracking-connect-button'),
            label: 'Connect',
            onPressed: onConnect,
            isLoading: isSubmitting,
          ),
        ),
      ],
    );
  }
}

class _ConnectedActions extends StatelessWidget {
  const _ConnectedActions({
    required this.isSubmitting,
    required this.onDisconnect,
  });

  final bool isSubmitting;
  final VoidCallback? onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This installation is configured for repair tracking updates.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        SecondaryButton(
          key: const Key('online-tracking-disconnect-button'),
          label: isSubmitting ? 'Removing...' : 'Remove Credential',
          icon: Icons.link_off,
          onPressed: isSubmitting ? null : onDisconnect,
        ),
      ],
    );
  }
}

class _ConnectionStatusBadge extends StatelessWidget {
  const _ConnectionStatusBadge({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.success : const Color(0xFF92400E);
    final background = connected
        ? const Color(0xFFF0FDF4)
        : const Color(0xFFFFFBEB);
    final label = connected ? 'Configured' : 'Not Connected';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyValue extends StatelessWidget {
  const _ReadOnlyValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        SelectableText(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _OnlineTrackingLoadingState extends StatelessWidget {
  const _OnlineTrackingLoadingState();

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

class _OnlineTrackingErrorState extends StatelessWidget {
  const _OnlineTrackingErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(label: 'Retry', onPressed: onRetry),
        ],
      ),
    );
  }
}

class _OnlineTrackingBanner extends StatelessWidget {
  const _OnlineTrackingBanner._({
    required this.message,
    required this.background,
    required this.border,
    required this.foreground,
    required this.icon,
  });

  factory _OnlineTrackingBanner.success(String message) {
    return _OnlineTrackingBanner._(
      message: message,
      background: const Color(0xFFF0FDF4),
      border: const Color(0xFFBBF7D0),
      foreground: AppColors.success,
      icon: Icons.check_circle_outline,
    );
  }

  factory _OnlineTrackingBanner.error(String message) {
    return _OnlineTrackingBanner._(
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
          Icon(icon, color: foreground, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
