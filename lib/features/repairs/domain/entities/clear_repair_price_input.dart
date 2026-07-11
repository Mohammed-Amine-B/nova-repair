class ClearRepairPriceInput {
  const ClearRepairPriceInput({required this.repairId}) : assert(repairId > 0);

  final int repairId;
}
