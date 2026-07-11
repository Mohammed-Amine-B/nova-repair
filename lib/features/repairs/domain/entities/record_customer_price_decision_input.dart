import '../customer_price_decision.dart';

class RecordCustomerPriceDecisionInput {
  RecordCustomerPriceDecisionInput({
    required this.repairId,
    required this.decision,
  }) {
    if (decision != CustomerPriceDecision.approved &&
        decision != CustomerPriceDecision.rejected) {
      throw ArgumentError.value(
        decision,
        'decision',
        'Customer response must be approved or rejected.',
      );
    }
  }

  final int repairId;
  final CustomerPriceDecision decision;
}
