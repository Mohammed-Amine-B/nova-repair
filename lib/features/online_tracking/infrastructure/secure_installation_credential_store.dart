import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../application/installation_credential_store.dart';

const installationSecretCredentialKey =
    'nova_repair.online_tracking.installation_secret';

class SecureInstallationCredentialStore implements InstallationCredentialStore {
  const SecureInstallationCredentialStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readInstallationSecret() {
    return _storage.read(key: installationSecretCredentialKey);
  }

  @override
  Future<void> writeInstallationSecret(String secret) {
    return _storage.write(key: installationSecretCredentialKey, value: secret);
  }

  @override
  Future<void> deleteInstallationSecret() {
    return _storage.delete(key: installationSecretCredentialKey);
  }

  @override
  Future<bool> hasInstallationSecret() async {
    final secret = await readInstallationSecret();
    return secret != null && secret.isNotEmpty;
  }
}
