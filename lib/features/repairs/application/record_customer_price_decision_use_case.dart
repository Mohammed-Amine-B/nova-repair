import '../domain/entities/record_customer_price_decision_input.dart';
import '../domain/entities/repair.dart';
import '../domain/repositories/repair_repository.dart';

class RecordCustomerPriceDecisionUseCase {
  const RecordCustomerPriceDecisionUseCase(this._repository);

  final RepairRepository _repository;

  Future<Repair> call(RecordCustomerPriceDecisionInput input) {
    return _repository.recordCustomerPriceDecision(input);
  }
}
