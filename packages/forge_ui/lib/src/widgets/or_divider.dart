import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';

/// A short [label] ("or") between two hairlines, separating two ways to do
/// the same thing (a password field and sign-in buttons).
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final line = Expanded(child: Container(height: 1, color: colors.line));
    return Row(
      spacing: Gap.sm,
      children: [
        line,
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall!
              .copyWith(color: colors.inkMuted),
        ),
        line,
      ],
    );
  }
}
