import 'package:flutter/material.dart';

enum AppDestination {
  dashboard(
    label: 'Dashboard',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  repairs(
    label: 'Repairs',
    icon: Icons.handyman_outlined,
    selectedIcon: Icons.handyman,
  ),
  settings(
    label: 'Settings',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
  );

  const AppDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
