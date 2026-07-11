import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/widgets/buttons/app_buttons.dart';
import '../../../app/widgets/form/app_text_field.dart';
import '../../common_problems/common_problem_providers.dart';
import '../../common_problems/domain/entities/common_problem.dart';
import '../../common_problems/domain/services/common_problem_title_normalizer.dart';

final commonProblemPickerTopProvider =
    FutureProvider.autoDispose<List<CommonProblem>>((ref) async {
      final problems = await ref
          .watch(commonProblemRepositoryProvider)
          .listCommonProblems();
      return problems.take(5).toList(growable: false);
    });

final commonProblemPickerSearchProvider = FutureProvider.autoDispose
    .family<List<CommonProblem>, String>((ref, query) async {
      final trimmed = query.trim();
      if (trimmed.isEmpty) {
        return const [];
      }

      return ref
          .watch(commonProblemRepositoryProvider)
          .searchCommonProblems(trimmed);
    });

class CommonProblemInsertionResult {
  const CommonProblemInsertionResult._({required this.inserted, this.message});

  const CommonProblemInsertionResult.inserted() : this._(inserted: true);

  const CommonProblemInsertionResult.duplicate() : this._(inserted: false);

  const CommonProblemInsertionResult.failure(String message)
    : this._(inserted: false, message: message);

  final bool inserted;
  final String? message;
}

class CommonProblemTextInserter {
  CommonProblemTextInserter({
    required this.textController,
    CommonProblemTitleNormalizer normalizer =
        const CommonProblemTitleNormalizer(),
  }) : _normalizer = normalizer;

  final TextEditingController textController;
  final CommonProblemTitleNormalizer _normalizer;

  bool containsProblem(CommonProblem problem) {
    final target = _normalizer.normalizeForDuplicateCheck(problem.title);
    for (final line in textController.text.split('\n')) {
      if (_normalizer.normalizeForDuplicateCheck(line) == target) {
        return true;
      }
    }
    return false;
  }

  void insertProblem(CommonProblem problem) {
    final current = textController.text;
    final normalizedTitle = _normalizer.normalizeTitle(problem.title);
    final next = current.trim().isEmpty
        ? normalizedTitle
        : '${current.trimRight()}\n$normalizedTitle';

    textController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
  }
}

class CommonProblemPicker extends ConsumerStatefulWidget {
  const CommonProblemPicker({
    required this.onProblemSelected,
    this.enabled = true,
    super.key,
  });

  final ValueChanged<CommonProblem> onProblemSelected;
  final bool enabled;

  @override
  ConsumerState<CommonProblemPicker> createState() =>
      _CommonProblemPickerState();
}

class _CommonProblemPickerState extends ConsumerState<CommonProblemPicker> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topProblemsAsync = ref.watch(commonProblemPickerTopProvider);
    final searchResultsAsync = ref.watch(
      commonProblemPickerSearchProvider(_searchQuery),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        topProblemsAsync.when(
          loading: () => const _CommonProblemsInlineLoading(),
          error: (_, _) => _CommonProblemsInlineError(
            onRetry: () => ref.invalidate(commonProblemPickerTopProvider),
          ),
          data: (problems) {
            if (problems.isEmpty) {
              return const _NoCommonProblemsHelper();
            }
            return _TopProblemsChips(
              problems: problems,
              enabled: widget.enabled,
              onSelected: widget.onProblemSelected,
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        AppTextField(
          key: const Key('common-problem-picker-search'),
          label: 'Search Common Problems',
          placeholder: 'Search common problems...',
          controller: _searchController,
          enabled: widget.enabled,
          suffix: const Icon(Icons.search, color: AppColors.textSecondary),
          onChanged: _onSearchChanged,
        ),
        if (_searchQuery.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          searchResultsAsync.when(
            loading: () => const _SearchResultsBox.loading(),
            error: (_, _) => _SearchResultsBox.error(
              onRetry: () => ref.invalidate(
                commonProblemPickerSearchProvider(_searchQuery),
              ),
            ),
            data: (results) => _SearchResultsBox.results(
              results: results,
              enabled: widget.enabled,
              onSelected: _selectSearchResult,
            ),
          ),
        ],
      ],
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) {
        return;
      }
      setState(() => _searchQuery = value);
    });
  }

  void _selectSearchResult(CommonProblem problem) {
    widget.onProblemSelected(problem);
    _searchDebounce?.cancel();
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }
}

class _TopProblemsChips extends StatelessWidget {
  const _TopProblemsChips({
    required this.problems,
    required this.enabled,
    required this.onSelected,
  });

  final List<CommonProblem> problems;
  final bool enabled;
  final ValueChanged<CommonProblem> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Common Problems',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final problem in problems)
              ActionChip(
                key: Key('common-problem-chip-${problem.id}'),
                label: Text(problem.title),
                onPressed: enabled ? () => onSelected(problem) : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _SearchResultsBox extends StatelessWidget {
  const _SearchResultsBox._({required this.child});

  const _SearchResultsBox.loading()
    : this._(
        child: const SizedBox(
          height: 48,
          child: Center(child: CircularProgressIndicator()),
        ),
      );

  factory _SearchResultsBox.error({required VoidCallback onRetry}) {
    return _SearchResultsBox._(
      child: Row(
        children: [
          const Expanded(child: Text('Common problems could not be loaded.')),
          SecondaryButton(label: 'Retry', onPressed: onRetry),
        ],
      ),
    );
  }

  factory _SearchResultsBox.results({
    required List<CommonProblem> results,
    required bool enabled,
    required ValueChanged<CommonProblem> onSelected,
  }) {
    if (results.isEmpty) {
      return const _SearchResultsBox._(
        child: Text('No matching common problems.'),
      );
    }

    return _SearchResultsBox._(
      child: Column(
        children: [
          for (var index = 0; index < results.length; index++) ...[
            if (index > 0) const Divider(height: 1, color: AppColors.border),
            _SearchResultTile(
              problem: results[index],
              enabled: enabled,
              onSelected: onSelected,
            ),
          ],
        ],
      ),
    );
  }

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: child,
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.problem,
    required this.enabled,
    required this.onSelected,
  });

  final CommonProblem problem;
  final bool enabled;
  final ValueChanged<CommonProblem> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('common-problem-search-result-${problem.id}'),
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: enabled ? () => onSelected(problem) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  problem.title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                problem.usageCount == 1
                    ? 'Used 1 time'
                    : 'Used ${problem.usageCount} times',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommonProblemsInlineLoading extends StatelessWidget {
  const _CommonProblemsInlineLoading();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Loading common problems...',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _CommonProblemsInlineError extends StatelessWidget {
  const _CommonProblemsInlineError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.error_outline, size: 18, color: AppColors.danger),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            'Common problems could not be loaded.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
          ),
        ),
        GhostButton(label: 'Retry', onPressed: onRetry),
      ],
    );
  }
}

class _NoCommonProblemsHelper extends StatelessWidget {
  const _NoCommonProblemsHelper();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Manage Common Problems in Settings to add quick problem templates.',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
    );
  }
}
