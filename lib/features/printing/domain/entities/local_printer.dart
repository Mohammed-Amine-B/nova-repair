class LocalPrinter {
  const LocalPrinter({
    required this.id,
    required this.displayName,
    required this.isDefault,
    this.isAvailable = true,
  });

  final String id;
  final String displayName;
  final bool isDefault;
  final bool isAvailable;
}
