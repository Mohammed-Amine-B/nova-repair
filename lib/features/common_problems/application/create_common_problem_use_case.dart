import '../domain/entities/common_problem.dart';
import '../domain/entities/create_common_problem_input.dart';
import '../domain/repositories/common_problem_repository.dart';

class CreateCommonProblemUseCase {
  const CreateCommonProblemUseCase(this._repository);

  final CommonProblemRepository _repository;

  Future<CommonProblem> call(CreateCommonProblemInput input) {
    return _repository.createCommonProblem(input);
  }
}
