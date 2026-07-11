enum CustomerPriceDecision {
  notRequested('not_requested'),
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const CustomerPriceDecision(this.databaseValue);

  final String databaseValue;

  static CustomerPriceDecision fromDatabaseValue(String value) {
    for (final decision in CustomerPriceDecision.values) {
      if (decision.databaseValue == value) {
        return decision;
      }
    }

    throw FormatException(
      'Unknown customer price decision database value: $value',
    );
  }
}
