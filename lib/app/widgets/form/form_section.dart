import 'package:flutter/material.dart';

import '../section_card.dart';

class FormSection extends StatelessWidget {
  const FormSection({
    required this.title,
    required this.child,
    this.description,
    super.key,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SectionCard(title: title, description: description, child: child);
  }
}
