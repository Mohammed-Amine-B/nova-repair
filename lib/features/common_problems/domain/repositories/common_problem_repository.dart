import '../entities/common_problem.dart';
import '../entities/create_common_problem_input.dart';
import '../entities/update_common_problem_input.dart';

abstract class CommonProblemRepository {
  Future<CommonProblem> createCommonProblem(CreateCommonProblemInput input);

  Future<CommonProblem> updateCommonProblemTitle(
    UpdateCommonProblemInput input,
  );

  Future<void> deleteCommonProblem(int id);

  Future<CommonProblem?> getCommonProblemById(int id);

  Future<List<CommonProblem>> listCommonProblems();

  Future<List<CommonProblem>> searchCommonProblems(String query);

  Future<CommonProblem> incrementUsage(int id);
}
