import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _page(List<Widget> children) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    for (final (i, child) in children.indexed) ...[
      if (i > 0) const SizedBox(height: Gap.sm),
      child,
    ],
  ],
);

const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

/// The card's sample week, Mon 9 to Sun 15 November 2026.
const _week = {
  9: DayState.done,
  10: DayState.light,
  11: DayState.missed,
  12: DayState.light,
  13: DayState.today,
  15: DayState.planned,
};

@widgetbook.UseCase(name: 'Week', type: WeekStrip)
Widget weekStrip(BuildContext context) => _page([
  WeekStrip(
    title: context.knobs.string(label: 'Title', initialValue: 'This week'),
    days: [
      for (var i = 0; i < 7; i++)
        WeekStripDay(
          weekday: _weekdays[i],
          number: '${9 + i}',
          state: _week[9 + i] ?? DayState.none,
        ),
    ],
    onDayTap: (_) {},
  ),
]);

@widgetbook.UseCase(name: 'Today and done', type: WeekStrip)
Widget weekStripTodayDone(BuildContext context) => _page([
  WeekStrip(
    title: 'This week',
    days: [
      for (var i = 0; i < 7; i++)
        WeekStripDay(
          weekday: _weekdays[i],
          number: '${9 + i}',
          state: switch (9 + i) {
            9 || 11 => DayState.done,
            10 || 12 => DayState.light,
            13 => DayState.todayDone,
            _ => DayState.none,
          },
        ),
    ],
    onDayTap: (_) {},
  ),
]);

@widgetbook.UseCase(name: 'Plain, in a SectionCard', type: WeekStrip)
Widget plainWeekStrip(BuildContext context) => _page([
  SectionCard(
    title: context.knobs.string(label: 'Title', initialValue: 'This week'),
    onTap: () {},
    child: WeekStrip.plain(
      days: [
        for (var i = 0; i < 7; i++)
          WeekStripDay(
            weekday: _weekdays[i],
            number: '${9 + i}',
            state: _week[9 + i] ?? DayState.none,
          ),
      ],
      onDayTap: (_) {},
    ),
  ),
]);
