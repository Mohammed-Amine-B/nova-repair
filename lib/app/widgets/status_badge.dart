import 'package:flutter/material.dart';

import '../../features/repairs/domain/repair_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, super.key});

  final RepairStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.status(status);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          status.displayLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

extension RepairStatusDisplay on RepairStatus {
  String get displayLabel {
    return switch (this) {
      RepairStatus.received => 'Received',
      RepairStatus.diagnosing => 'Diagnosing',
      RepairStatus.waitingForCustomerApproval =>
        'Waiting for Customer Approval',
      RepairStatus.waitingForPart => 'Waiting for Part',
      RepairStatus.repairing => 'Repairing',
      RepairStatus.readyForPickup => 'Ready for Pickup',
      RepairStatus.delivered => 'Delivered',
      RepairStatus.cancelled => 'Cancelled',
    };
  }
}
