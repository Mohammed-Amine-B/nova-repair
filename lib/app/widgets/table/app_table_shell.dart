import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

class AppTableShell extends StatelessWidget {
  const AppTableShell({
    required this.child,
    this.header,
    this.expandChild = false,
    super.key,
  });

  final Widget? header;
  final Widget child;
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.softSurface,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: DefaultTextStyle.merge(
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                  child: header!,
                ),
              ),
            ),
          if (expandChild) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

class AppTableRowShell extends StatelessWidget {
  const AppTableRowShell({required this.child, this.onTap, super.key});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.canvas,
        child: Container(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.tableRowMinHeight,
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.softSurface)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: child,
        ),
      ),
    );
  }
}
