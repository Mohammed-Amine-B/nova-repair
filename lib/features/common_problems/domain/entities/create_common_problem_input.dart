import '../errors/common_problem_exception.dart';
import '../services/common_problem_title_normalizer.dart';

class CreateCommonProblemInput {
  CreateCommonProblemInput({
    required this.title,
    CommonProblemTitleNormalizer normalizer =
        const CommonProblemTitleNormalizer(),
  }) : normalizedTitle = normalizer.normalizeTitle(title) {
    if (normalizedTitle.isEmpty) {
      throw const InvalidCommonProblemTitleException();
    }
  }

  final String title;
  final String normalizedTitle;
}
