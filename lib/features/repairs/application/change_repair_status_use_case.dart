import '../domain/entities/change_repair_status_input.dart';
import '../domain/entities/repair.dart';
import '../domain/repositories/repair_repository.dart';

class ChangeRepairStatusUseCase {
  const ChangeRepairStatusUseCase(this._repository);

  final RepairRepository _repository;

  Future<Repair> call(ChangeRepairStatusInput input) {
    return _repository.changeStatus(input);
  }
}
