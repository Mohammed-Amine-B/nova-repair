import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/widgets/buttons/app_buttons.dart';
import '../../app/widgets/dialogs/confirmation_dialog.dart';
import '../../app/widgets/form/app_text_field.dart';
import '../../app/widgets/page_header.dart';
import '../../app/widgets/section_card.dart';
import 'domain/entities/common_problem.dart';
import 'presentation/common_problems_controller.dart';
import 'presentation/common_problems_state.dart';

class CommonProblemsPage extends ConsumerStatefulWidget {
  const CommonProblemsPage({required this.onBackToSettings, super.key});

  final VoidCallback onBackToSettings;

  @override
  ConsumerState<CommonProblemsPage> createState() => _CommonProblemsPageState();
}

class _CommonProblemsPageState extends ConsumerState<CommonProblemsPage> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(commonProblemsListProvider);
    final state = ref.watch(commonProblemsControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GhostButton(
                  key: const Key('common-problems-back-to-settings'),
                  label: 'Back to Settings',
                  icon: Icons.arrow_back,
                  onPressed: widget.onBackToSettings,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const PageHeader(
                title: 'Common Problems',
                subtitle: 'Manage frequently used repair problem templates',
              ),
              const SizedBox(height: AppSpacing.xl),
              _CommonProblemsToolbar(
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onAdd: () => _showProblemDialog(),
              ),
              const SizedBox(height: AppSpacing.xl),
              listAsync.when(
                loading: () => const _CommonProblemsLoadingState(),
                error: (_, _) => _CommonProblemsErrorState(
                  onRetry: () => ref.invalidate(commonProblemsListProvider),
                ),
                data: (problems) => _CommonProblemsListSection(
                  problems: problems,
                  isSearching: state.searchQuery.trim().isNotEmpty,
                  deletingProblemId: state.deletingProblemId,
                  onAdd: () => _showProblemDialog(),
                  onEdit: (problem) => _showProblemDialog(problem: problem),
                  onDelete: _confirmDelete,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) {
        return;
      }
      ref.read(commonProblemsControllerProvider.notifier).setSearchQuery(value);
    });
  }

  Future<void> _showProblemDialog({CommonProblem? problem}) async {
    ref.read(commonProblemsControllerProvider.notifier).clearMutationError();
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => _CommonProblemEditorDialog(problem: problem),
    );
  }

  Future<void> _confirmDelete(CommonProblem problem) async {
    final problemId = problem.id;
    if (problemId == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return ConfirmationDialog(
          title: 'Delete Common Problem?',
          message: 'This removes the template from your Common Problems list.',
          cancelLabel: 'Cancel',
          confirmLabel: 'Delete',
          destructive: true,
          icon: Icons.delete_outline,
          onCancel: () => Navigator.of(context).pop(false),
          onConfirm: () => Navigator.of(context).pop(true),
          content: Text(
            'Existing repairs will not be changed.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await ref
        .read(commonProblemsControllerProvider.notifier)
        .deleteProblem(problemId);
  }
}

class _CommonProblemsToolbar extends StatelessWidget {
  const _CommonProblemsToolbar({
    required this.searchController,
    required this.onSearchChanged,
    required this.onAdd,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final searchField = AppTextField(
            key: const Key('common-problems-search-field'),
            label: 'Search',
            placeholder: 'Search common problems...',
            controller: searchController,
            onChanged: onSearchChanged,
            suffix: const Icon(Icons.search, color: AppColors.textSecondary),
          );

          final addButton = PrimaryButton(
            key: const Key('common-problems-add-button'),
            label: 'Add Common Problem',
            icon: Icons.add,
            onPressed: onAdd,
          );

          if (constraints.maxWidth < 700) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                searchField,
                const SizedBox(height: AppSpacing.md),
                Align(alignment: Alignment.centerLeft, child: addButton),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: searchField),
              const SizedBox(width: AppSpacing.lg),
              addButton,
            ],
          );
        },
      ),
    );
  }
}

class _CommonProblemsListSection extends StatelessWidget {
  const _CommonProblemsListSection({
    required this.problems,
    required this.isSearching,
    required this.deletingProblemId,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CommonProblem> problems;
  final bool isSearching;
  final int? deletingProblemId;
  final VoidCallback onAdd;
  final ValueChanged<CommonProblem> onEdit;
  final ValueChanged<CommonProblem> onDelete;

  @override
  Widget build(BuildContext context) {
    if (problems.isEmpty) {
      return isSearching
          ? const _SearchEmptyState()
          : _CreateEmptyState(onAdd: onAdd);
    }

    return SectionCard(
      title: 'Problem Templates',
      child: Column(
        children: [
          for (var index = 0; index < problems.length; index++) ...[
            if (index > 0) const Divider(height: 1, color: AppColors.border),
            _CommonProblemRow(
              problem: problems[index],
              isDeleting: deletingProblemId == problems[index].id,
              onEdit: () => onEdit(problems[index]),
              onDelete: () => onDelete(problems[index]),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommonProblemRow extends StatelessWidget {
  const _CommonProblemRow({
    required this.problem,
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  final CommonProblem problem;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  problem.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  problem.usageLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          GhostButton(
            key: Key('common-problem-edit-${problem.id}'),
            label: 'Edit',
            icon: Icons.edit_outlined,
            onPressed: isDeleting ? null : onEdit,
          ),
          const SizedBox(width: AppSpacing.xs),
          GhostButton(
            key: Key('common-problem-delete-${problem.id}'),
            label: 'Delete',
            icon: Icons.delete_outline,
            isLoading: isDeleting,
            onPressed: isDeleting ? null : onDelete,
          ),
        ],
      ),
    );
  }
}

class _CommonProblemEditorDialog extends ConsumerStatefulWidget {
  const _CommonProblemEditorDialog({this.problem});

  final CommonProblem? problem;

  @override
  ConsumerState<_CommonProblemEditorDialog> createState() =>
      _CommonProblemEditorDialogState();
}

class _CommonProblemEditorDialogState
    extends ConsumerState<_CommonProblemEditorDialog> {
  late final TextEditingController _controller;
  String? _fieldError;

  bool get _isEditing => widget.problem != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.problem?.title ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(commonProblemsControllerProvider);
    final problemId = widget.problem?.id;
    final isSaving = _isEditing
        ? state.updatingProblemId == problemId
        : state.isCreating;
    final errorText = _fieldError ?? state.mutationError;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.dialog),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing ? 'Edit Common Problem' : 'Add Common Problem',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      key: const Key('common-problem-title-field'),
                      label: 'Problem',
                      placeholder: 'Enter a frequently used problem',
                      controller: _controller,
                      errorText: errorText,
                      enabled: !isSaving,
                      onChanged: (_) {
                        if (_fieldError != null) {
                          setState(() => _fieldError = null);
                        }
                        ref
                            .read(commonProblemsControllerProvider.notifier)
                            .clearMutationError();
                      },
                    ),
                  ],
                ),
              ),
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.softSurface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GhostButton(
                        label: 'Cancel',
                        onPressed: isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      PrimaryButton(
                        key: const Key('common-problem-dialog-submit'),
                        label: _isEditing ? 'Save Changes' : 'Add Problem',
                        isLoading: isSaving,
                        onPressed: isSaving ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final title = _controller.text;
    if (title.trim().isEmpty) {
      setState(() => _fieldError = 'Problem is required.');
      return;
    }

    final controller = ref.read(commonProblemsControllerProvider.notifier);
    final saved = _isEditing
        ? await controller.updateProblem(id: widget.problem!.id!, title: title)
        : await controller.createProblem(title);

    if (saved && mounted) {
      Navigator.of(context).pop();
    }
  }
}

class _CommonProblemsLoadingState extends StatelessWidget {
  const _CommonProblemsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      child: SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _CommonProblemsErrorState extends StatelessWidget {
  const _CommonProblemsErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Common problems could not be loaded.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          SecondaryButton(
            key: const Key('common-problems-retry-button'),
            label: 'Retry',
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _CreateEmptyState extends StatelessWidget {
  const _CreateEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: _EmptyStateContent(
        title: 'No common problems yet',
        description:
            'Add frequently used repair problems to speed up repair intake.',
        action: PrimaryButton(
          key: const Key('common-problems-empty-add-button'),
          label: 'Add Common Problem',
          icon: Icons.add,
          onPressed: onAdd,
        ),
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      child: _EmptyStateContent(
        title: 'No matching problems',
        description: 'Try a different search.',
      ),
    );
  }
}

class _EmptyStateContent extends StatelessWidget {
  const _EmptyStateContent({
    required this.title,
    required this.description,
    this.action,
  });

  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: const Icon(
                Icons.build_circle_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
