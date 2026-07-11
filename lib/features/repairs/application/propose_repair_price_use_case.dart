import '../domain/entities/propose_repair_price_input.dart';
import '../domain/entities/repair.dart';
import '../domain/repositories/repair_repository.dart';

class ProposeRepairPriceUseCase {
  const ProposeRepairPriceUseCase(this._repository);

  final RepairRepository _repository;

  Future<Repair> call(ProposeRepairPriceInput input) {
    return _repository.proposePrice(input);
  }
}
