import 'package:flutter/material.dart';

import '../spacing.dart';

/// The small heading over a group of cards or rows ("Units"): 13px
/// semibold ink-muted, 8px above and below, 4px in from the cards' edge.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Gap.xs, vertical: Gap.sm),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    ),
  );
}
