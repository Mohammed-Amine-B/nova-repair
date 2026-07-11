import 'package:flutter/material.dart';

import '../../features/repairs/domain/repair_status.dart';

class AppColors {
  const AppColors._();

  static const canvas = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const softSurface = Color(0xFFF1F5F9);
  static const primary = Color(0xFF2563EB);
  static const primaryHover = Color(0xFF1D4ED8);
  static const primarySoft = Color(0xFFEFF6FF);
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);
  static const borderStrong = Color(0xFFCBD5E1);
  static const success = Color(0xFF166534);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEF2F2);

  static const received = StatusBadgeColors(
    background: Color(0xFFE2E8F0),
    foreground: Color(0xFF475569),
  );
  static const diagnosing = StatusBadgeColors(
    background: Color(0xFFEDE9FE),
    foreground: Color(0xFF5B21B6),
  );
  static const waitingForCustomerApproval = StatusBadgeColors(
    background: Color(0xFFFEF3C7),
    foreground: Color(0xFF92400E),
  );
  static const waitingForPart = StatusBadgeColors(
    background: Color(0xFFFFEDD5),
    foreground: Color(0xFFEA580C),
  );
  static const repairing = StatusBadgeColors(
    background: Color(0xFFEFF6FF),
    foreground: Color(0xFF1D4ED8),
  );
  static const readyForPickup = StatusBadgeColors(
    background: Color(0xFFDCFCE7),
    foreground: Color(0xFF166534),
  );
  static const delivered = StatusBadgeColors(
    background: Color(0xFFF1F5F9),
    foreground: Color(0xFF475569),
  );
  static const cancelled = StatusBadgeColors(
    background: Color(0xFFFEE2E2),
    foreground: Color(0xFFB91C1C),
  );

  static StatusBadgeColors status(RepairStatus status) {
    return switch (status) {
      RepairStatus.received => received,
      RepairStatus.diagnosing => diagnosing,
      RepairStatus.waitingForCustomerApproval => waitingForCustomerApproval,
      RepairStatus.waitingForPart => waitingForPart,
      RepairStatus.repairing => repairing,
      RepairStatus.readyForPickup => readyForPickup,
      RepairStatus.delivered => delivered,
      RepairStatus.cancelled => cancelled,
    };
  }
}

class StatusBadgeColors {
  const StatusBadgeColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}
