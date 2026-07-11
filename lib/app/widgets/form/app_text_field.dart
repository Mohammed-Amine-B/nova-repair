import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.helperText,
    this.placeholder,
    this.suffix,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    super.key,
  });

  final String label;
  final String? helperText;
  final String? placeholder;
  final Widget? suffix;
  final String? errorText;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return _FieldFrame(
      label: label,
      helperText: helperText,
      errorText: errorText,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        enabled: enabled,
        readOnly: readOnly,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: placeholder,
          suffixIcon: suffix,
          errorText: errorText,
        ),
      ),
    );
  }
}

class AppTextArea extends StatelessWidget {
  const AppTextArea({
    required this.label,
    this.helperText,
    this.placeholder,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
    this.controller,
    this.onChanged,
    this.minLines = 3,
    super.key,
  });

  final String label;
  final String? helperText;
  final String? placeholder;
  final String? errorText;
  final bool enabled;
  final bool readOnly;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return _FieldFrame(
      label: label,
      helperText: helperText,
      errorText: errorText,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        enabled: enabled,
        readOnly: readOnly,
        minLines: minLines,
        maxLines: null,
        decoration: InputDecoration(
          hintText: placeholder,
          errorText: errorText,
          alignLabelWithHint: true,
        ),
      ),
    );
  }
}

class _FieldFrame extends StatelessWidget {
  const _FieldFrame({
    required this.label,
    required this.child,
    this.helperText,
    this.errorText,
  });

  final String label;
  final String? helperText;
  final String? errorText;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        child,
        if (helperText != null && errorText == null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(helperText!, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}
