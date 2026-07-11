import '../domain/repositories/common_problem_repository.dart';

class DeleteCommonProblemUseCase {
  const DeleteCommonProblemUseCase(this._repository);

  final CommonProblemRepository _repository;

  Future<void> call(int id) {
    return _repository.deleteCommonProblem(id);
  }
}
