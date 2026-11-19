import 'package:flutter/material.dart';

import '../spacing.dart';
import 'benefit_list.dart';
import 'card_frame.dart';
import 'forge_button.dart';
import 'forge_tag.dart';

/// A plain card that offers a plan: the [title] with an optional [tag]
/// (e.g. a trial) beside it, the [benefits] checked, and the primary
/// [actionLabel] button. The tag goes under the title when both do not fit
/// (larger text).
class PlanCard extends StatelessWidget {
  const PlanCard({
    super.key,
    required this.title,
    this.tag,
    required this.benefits,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String? tag;
  final List<String> benefits;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final tag = this.tag;
    return CardFrame(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Gap.md,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: Gap.sm,
              runSpacing: Gap.xs,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (tag != null) ForgeTag(tag),
              ],
            ),
            BenefitList.checked(benefits),
            ForgeButton(label: actionLabel, onPressed: onAction),
          ],
        ),
      ),
    );
  }
}
