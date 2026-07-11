import '../domain/entities/create_warranty_return_input.dart';
import '../domain/entities/repair.dart';
import '../domain/repositories/repair_repository.dart';

class CreateWarrantyReturnUseCase {
  const CreateWarrantyReturnUseCase(this._repository);

  final RepairRepository _repository;

  Future<Repair> call(CreateWarrantyReturnInput input) {
    return _repository.createWarrantyReturn(input);
  }
}
