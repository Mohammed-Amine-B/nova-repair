import '../domain/entities/common_problem.dart';

class CommonProblemsState {
  const CommonProblemsState({
    this.searchQuery = '',
    this.isCreating = false,
    this.updatingProblemId,
    this.deletingProblemId,
    this.mutationError,
    this.reloadRevision = 0,
  });

  final String searchQuery;
  final bool isCreating;
  final int? updatingProblemId;
  final int? deletingProblemId;
  final String? mutationError;
  final int reloadRevision;

  bool get isMutating =>
      isCreating || updatingProblemId != null || deletingProblemId != null;

  CommonProblemsState copyWith({
    String? searchQuery,
    bool? isCreating,
    int? updatingProblemId,
    int? deletingProblemId,
    String? mutationError,
    int? reloadRevision,
    bool clearUpdatingProblemId = false,
    bool clearDeletingProblemId = false,
    bool clearMutationError = false,
  }) {
    return CommonProblemsState(
      searchQuery: searchQuery ?? this.searchQuery,
      isCreating: isCreating ?? this.isCreating,
      updatingProblemId: clearUpdatingProblemId
          ? null
          : updatingProblemId ?? this.updatingProblemId,
      deletingProblemId: clearDeletingProblemId
          ? null
          : deletingProblemId ?? this.deletingProblemId,
      mutationError: clearMutationError
          ? null
          : mutationError ?? this.mutationError,
      reloadRevision: reloadRevision ?? this.reloadRevision,
    );
  }
}

extension CommonProblemUsageLabel on CommonProblem {
  String get usageLabel {
    return usageCount == 1 ? 'Used 1 time' : 'Used $usageCount times';
  }
}
