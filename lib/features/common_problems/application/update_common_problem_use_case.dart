import '../domain/entities/common_problem.dart';
import '../domain/entities/update_common_problem_input.dart';
import '../domain/repositories/common_problem_repository.dart';

class UpdateCommonProblemUseCase {
  const UpdateCommonProblemUseCase(this._repository);

  final CommonProblemRepository _repository;

  Future<CommonProblem> call(UpdateCommonProblemInput input) {
    return _repository.updateCommonProblemTitle(input);
  }
}
