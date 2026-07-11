import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../common_problems/common_problem_providers.dart';
import '../../common_problems/domain/entities/common_problem.dart';
import 'common_problem_picker.dart';

final commonProblemInsertionControllerProvider =
    NotifierProvider.autoDispose<
      CommonProblemInsertionController,
      CommonProblemInsertionState
    >(CommonProblemInsertionController.new);

class CommonProblemInsertionState {
  const CommonProblemInsertionState({
    this.isInserting = false,
    this.errorMessage,
  });

  final bool isInserting;
  final String? errorMessage;

  CommonProblemInsertionState copyWith({
    bool? isInserting,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CommonProblemInsertionState(
      isInserting: isInserting ?? this.isInserting,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

class CommonProblemInsertionController
    extends Notifier<CommonProblemInsertionState> {
  @override
  CommonProblemInsertionState build() {
    return const CommonProblemInsertionState();
  }

  Future<CommonProblemInsertionResult> insertProblem({
    required TextEditingController textController,
    required CommonProblem problem,
  }) async {
    if (state.isInserting) {
      return const CommonProblemInsertionResult.duplicate();
    }

    final inserter = CommonProblemTextInserter(textController: textController);
    if (inserter.containsProblem(problem)) {
      state = state.copyWith(clearErrorMessage: true);
      return const CommonProblemInsertionResult.duplicate();
    }

    state = state.copyWith(isInserting: true, clearErrorMessage: true);
    try {
      await ref.read(incrementCommonProblemUsageUseCaseProvider)(problem.id!);
      inserter.insertProblem(problem);
      ref
        ..invalidate(commonProblemPickerTopProvider)
        ..invalidate(commonProblemPickerSearchProvider);
      state = state.copyWith(isInserting: false);
      return const CommonProblemInsertionResult.inserted();
    } catch (_) {
      const message = 'The problem could not be added. Please try again.';
      state = state.copyWith(isInserting: false, errorMessage: message);
      return const CommonProblemInsertionResult.failure(message);
    }
  }

  void clearError() {
    state = state.copyWith(clearErrorMessage: true);
  }
}
