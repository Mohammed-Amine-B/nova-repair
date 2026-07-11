import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common_problem_providers.dart';
import '../domain/entities/common_problem.dart';
import '../domain/entities/create_common_problem_input.dart';
import '../domain/entities/update_common_problem_input.dart';
import '../domain/errors/common_problem_exception.dart';
import 'common_problems_state.dart';

final commonProblemsListProvider =
    FutureProvider.autoDispose<List<CommonProblem>>((ref) {
      final selection = ref.watch(
        commonProblemsControllerProvider.select(
          (state) => (state.searchQuery, state.reloadRevision),
        ),
      );
      final query = selection.$1;
      final repository = ref.watch(commonProblemRepositoryProvider);
      if (query.trim().isEmpty) {
        return repository.listCommonProblems();
      }
      return repository.searchCommonProblems(query);
    });

final commonProblemsControllerProvider =
    NotifierProvider.autoDispose<CommonProblemsController, CommonProblemsState>(
      CommonProblemsController.new,
    );

class CommonProblemsController extends Notifier<CommonProblemsState> {
  @override
  CommonProblemsState build() {
    return const CommonProblemsState();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, clearMutationError: true);
  }

  void clearMutationError() {
    state = state.copyWith(clearMutationError: true);
  }

  Future<bool> createProblem(String title) async {
    if (state.isCreating) {
      return false;
    }

    state = state.copyWith(isCreating: true, clearMutationError: true);
    try {
      await ref.read(createCommonProblemUseCaseProvider)(
        CreateCommonProblemInput(title: title),
      );
      state = state.copyWith(
        isCreating: false,
        reloadRevision: state.reloadRevision + 1,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        isCreating: false,
        mutationError: _safeMessage(error),
      );
      return false;
    }
  }

  Future<bool> updateProblem({required int id, required String title}) async {
    if (state.updatingProblemId != null) {
      return false;
    }

    state = state.copyWith(updatingProblemId: id, clearMutationError: true);
    try {
      await ref.read(updateCommonProblemUseCaseProvider)(
        UpdateCommonProblemInput(id: id, title: title),
      );
      state = state.copyWith(
        clearUpdatingProblemId: true,
        reloadRevision: state.reloadRevision + 1,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        clearUpdatingProblemId: true,
        mutationError: _safeMessage(error),
      );
      return false;
    }
  }

  Future<bool> deleteProblem(int id) async {
    if (state.deletingProblemId != null) {
      return false;
    }

    state = state.copyWith(deletingProblemId: id, clearMutationError: true);
    try {
      await ref.read(deleteCommonProblemUseCaseProvider)(id);
      state = state.copyWith(
        clearDeletingProblemId: true,
        reloadRevision: state.reloadRevision + 1,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        clearDeletingProblemId: true,
        mutationError: _safeMessage(error),
      );
      return false;
    }
  }

  String _safeMessage(Object error) {
    if (error is InvalidCommonProblemTitleException) {
      return 'Problem is required.';
    }
    if (error is DuplicateCommonProblemTitleException) {
      return 'This problem already exists.';
    }
    if (error is CommonProblemNotFoundException) {
      return 'This problem could not be found.';
    }
    return 'Common problem could not be saved. Please try again.';
  }
}
