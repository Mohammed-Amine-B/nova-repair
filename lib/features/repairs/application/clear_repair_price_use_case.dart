import '../domain/entities/clear_repair_price_input.dart';
import '../domain/entities/repair.dart';
import '../domain/repositories/repair_repository.dart';

class ClearRepairPriceUseCase {
  const ClearRepairPriceUseCase(this._repository);

  final RepairRepository _repository;

  Future<Repair> call(ClearRepairPriceInput input) {
    return _repository.clearPrice(input);
  }
}
