import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class EmptyValueText extends StatelessWidget {
  const EmptyValueText({this.value = '—', super.key});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
