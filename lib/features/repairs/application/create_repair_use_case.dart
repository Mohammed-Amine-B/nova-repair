import '../domain/entities/create_repair_input.dart';
import '../domain/entities/repair.dart';
import '../domain/repositories/repair_repository.dart';

class CreateRepairUseCase {
  const CreateRepairUseCase(this._repository);

  final RepairRepository _repository;

  Future<Repair> call(CreateRepairInput input) {
    return _repository.createRepair(input);
  }
}
