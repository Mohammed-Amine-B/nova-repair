import 'package:flutter/material.dart';

import '../navigation/app_destination.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class NovaSidebar extends StatelessWidget {
  const NovaSidebar({
    required this.selectedDestination,
    required this.onDestinationSelected,
    required this.shopName,
    this.shopSubtitle,
    super.key,
  });

  final AppDestination selectedDestination;
  final ValueChanged<AppDestination> onDestinationSelected;
  final String shopName;
  final String? shopSubtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _SidebarBrand(),
              ),
              const SizedBox(height: AppSpacing.xxl),
              for (final destination in AppDestination.values)
                _SidebarDestinationItem(
                  destination: destination,
                  selected: destination == selectedDestination,
                  onTap: () => onDestinationSelected(destination),
                ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: _ShopIdentity(
                  shopName: shopName,
                  shopSubtitle: shopSubtitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  const _SidebarBrand();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nova Repair',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'Management System',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SidebarDestinationItem extends StatelessWidget {
  const _SidebarDestinationItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = selected
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Material(
        color: selected ? AppColors.primarySoft : Colors.transparent,
        child: InkWell(
          key: Key('nova-sidebar-item-${destination.name}'),
          onTap: onTap,
          hoverColor: AppColors.softSurface,
          child: SizedBox(
            height: 42,
            child: Row(
              children: [
                AnimatedContainer(
                  key: selected
                      ? Key('nova-sidebar-item-${destination.name}-selected')
                      : null,
                  duration: Duration.zero,
                  width: 4,
                  height: double.infinity,
                  color: selected ? AppColors.primary : Colors.transparent,
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  size: 20,
                  color: selected ? AppColors.primary : foreground,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  destination.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopIdentity extends StatelessWidget {
  const _ShopIdentity({required this.shopName, required this.shopSubtitle});

  final String shopName;
  final String? shopSubtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.softSurface,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (shopSubtitle != null)
                  Text(
                    shopSubtitle!,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
