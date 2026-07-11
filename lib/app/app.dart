import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'theme/app_theme.dart';

class NovaRepairApp extends StatelessWidget {
  const NovaRepairApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nova Repair',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AppShell(),
    );
  }
}
