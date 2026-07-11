import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/tracking_installation_verifier.dart';
import '../online_tracking_providers.dart';
import 'online_tracking_connection_state.dart';

final onlineTrackingConnectionControllerProvider =
    NotifierProvider.autoDispose<
      OnlineTrackingConnectionController,
      OnlineTrackingConnectionState
    >(OnlineTrackingConnectionController.new);

class OnlineTrackingConnectionController
    extends Notifier<OnlineTrackingConnectionState> {
  @override
  OnlineTrackingConnectionState build() {
    return const OnlineTrackingConnectionState();
  }

  void clearFeedback() {
    state = state.copyWith(
      clearSecretInputError: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );
  }

  Future<bool> connect({
    required String publicShopId,
    required String installationSecret,
  }) async {
    if (state.isSubmitting) {
      return false;
    }

    final trimmedSecret = installationSecret.trim();
    if (trimmedSecret.isEmpty) {
      state = state.copyWith(
        secretInputError: 'Installation secret is required.',
        clearErrorMessage: true,
        clearSuccessMessage: true,
      );
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearSecretInputError: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );

    try {
      final result = await ref
          .read(trackingInstallationVerifierProvider)
          .verify(
            publicShopId: publicShopId,
            installationSecret: trimmedSecret,
          );

      if (result == TrackingInstallationVerificationResult.invalidCredentials) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'The shop ID or installation secret is invalid.',
        );
        return false;
      }

      if (result == TrackingInstallationVerificationResult.unavailable) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'Connection could not be verified. Please try again.',
        );
        return false;
      }

      try {
        await ref
            .read(installationCredentialStoreProvider)
            .writeInstallationSecret(trimmedSecret);
      } catch (_) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage:
              'The connection was verified, but the credential could not be saved securely.',
        );
        return false;
      }

      ref.invalidate(installationCredentialExistsProvider);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Online tracking credential saved.',
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Connection could not be verified. Please try again.',
      );
      return false;
    }
  }

  Future<bool> disconnect() async {
    if (state.isSubmitting) {
      return false;
    }

    state = state.copyWith(
      isSubmitting: true,
      clearSecretInputError: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    );

    try {
      await ref
          .read(installationCredentialStoreProvider)
          .deleteInstallationSecret();
      ref.invalidate(installationCredentialExistsProvider);
      state = state.copyWith(
        isSubmitting: false,
        successMessage: 'Online tracking credential removed.',
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage:
            'Online tracking credentials could not be read from this device.',
      );
      return false;
    }
  }
}
