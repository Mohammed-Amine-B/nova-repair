import '../domain/entities/common_problem.dart';
import '../domain/repositories/common_problem_repository.dart';

class IncrementCommonProblemUsageUseCase {
  const IncrementCommonProblemUsageUseCase(this._repository);

  final CommonProblemRepository _repository;

  Future<CommonProblem> call(int id) {
    return _repository.incrementUsage(id);
  }
}
