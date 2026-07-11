sealed class PrintPrinterTarget {
  const PrintPrinterTarget();

  const factory PrintPrinterTarget.systemDefault() =
      SystemDefaultPrintPrinterTarget;

  const factory PrintPrinterTarget.printerId(String id) =
      SpecificPrintPrinterTarget;
}

class SystemDefaultPrintPrinterTarget extends PrintPrinterTarget {
  const SystemDefaultPrintPrinterTarget();
}

class SpecificPrintPrinterTarget extends PrintPrinterTarget {
  const SpecificPrintPrinterTarget(this.id);

  final String id;
}
