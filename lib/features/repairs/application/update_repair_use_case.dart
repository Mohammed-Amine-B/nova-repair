import '../domain/entities/repair.dart';
import '../domain/entities/update_repair_input.dart';
import '../domain/repositories/repair_repository.dart';

class UpdateRepairUseCase {
  const UpdateRepairUseCase(this._repository);

  final RepairRepository _repository;

  Future<Repair> call(UpdateRepairInput input) {
    return _repository.updateRepairDetails(input);
  }
}
