class ProposeRepairPriceInput {
  ProposeRepairPriceInput({required this.repairId, required this.priceAmount}) {
    if (priceAmount < 0) {
      throw ArgumentError.value(
        priceAmount,
        'priceAmount',
        'Cannot be negative.',
      );
    }
  }

  final int repairId;

  /// Integer DZD amount with no decimal places.
  final int priceAmount;
}
