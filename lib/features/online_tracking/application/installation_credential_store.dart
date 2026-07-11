abstract class InstallationCredentialStore {
  Future<String?> readInstallationSecret();

  Future<void> writeInstallationSecret(String secret);

  Future<void> deleteInstallationSecret();

  Future<bool> hasInstallationSecret();
}
