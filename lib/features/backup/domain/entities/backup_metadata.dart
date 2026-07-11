class BackupMetadata {
  const BackupMetadata({
    required this.filePath,
    required this.fileName,
    required this.createdAt,
    required this.fileSizeBytes,
    required this.schemaVersion,
    required this.repairCount,
  });

  final String filePath;
  final String fileName;
  final DateTime createdAt;
  final int fileSizeBytes;
  final int schemaVersion;
  final int repairCount;
}
