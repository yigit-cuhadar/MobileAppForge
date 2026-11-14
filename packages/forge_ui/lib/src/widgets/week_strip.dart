import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';
import 'card_frame.dart';
import 'day_circle.dart';

/// One day of a [WeekStrip]: its weekday letter, date number and state.
class WeekStripDay {
  const WeekStripDay({
    required this.weekday,
    required this.number,
    required this.state,
  });

  final String weekday;
  final String number;
  final DayState state;
}

/// A week of day circles in a card under its [title], in the MonthGrid
/// language. Each day is a button.
class WeekStrip extends StatelessWidget {
  const WeekStrip({
    super.key,
    required String this.title,
    required this.days,
    required this.onDayTap,
  });

  /// Only the weekday letters and day circles, for a card that draws its
  /// own title, such as a SectionCard.
  const WeekStrip.plain({super.key, required this.days, required this.onDayTap})
    : title = null;

  final String? title;
  final List<WeekStripDay> days;
  final void Function(int index) onDayTap;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final text = Theme.of(context).textTheme;
    final week = Row(
      spacing: 2,
      children: [
        for (final (i, day) in days.indexed)
          Expanded(
            child: Semantics(
              button: true,
              child: InkWell(
                onTap: () => onDayTap(i),
                borderRadius: BorderRadius.circular(style.radii.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: Gap.sm),
                  child: Column(
                    spacing: Gap.xs,
                    children: [
                      Text(
                        day.weekday,
                        style: text.labelMedium!.copyWith(
                          color: style.colors.inkMuted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      DayCircle(state: day.state, number: day.number),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    final title = this.title;
    if (title == null) return week;
    return CardFrame(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.sm,
          vertical: Gap.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Gap.sm,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
              child: Text(title, style: text.titleMedium),
            ),
            week,
          ],
        ),
      ),
    );
  }
}
