import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';
import 'card_frame.dart';
import 'day_circle.dart';
import 'skeleton.dart';

/// A month of day circles in a card: a [summary] line, the [weekdays]
/// letters, the weeks that hold the month and a [legend]. Days of the
/// weeks outside the month show at 35%. A PeriodSelector above the card
/// changes the month.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required DateTime this.month,
    required this.firstWeekday,
    required this.weekdays,
    required DayState Function(DateTime day) this.stateOf,
    required String this.summary,
    required Map<DayState, String> this.legend,
  });

  /// The weekday letters stay; the summary, days and legend shimmer.
  const MonthGrid.loading({super.key, required this.weekdays})
    : month = null,
      firstWeekday = DateTime.monday,
      stateOf = null,
      summary = null,
      legend = null;

  /// Any day of the month to show.
  final DateTime? month;

  /// The week's first day, [DateTime.monday] to [DateTime.sunday].
  final int firstWeekday;

  /// Seven letters, from [firstWeekday] on.
  final List<String> weekdays;
  final DayState Function(DateTime day)? stateOf;
  final String? summary;

  /// The states the month uses, in order, with the app's names for them.
  final Map<DayState, String>? legend;

  static const double _outsideOpacity = 0.35;

  /// The loading grid's rows: the most a month can need.
  static const int _loadingWeeks = 6;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final text = Theme.of(context).textTheme;
    final month = this.month;
    final letters = _week([
      for (final letter in weekdays)
        Text(
          letter,
          textAlign: TextAlign.center,
          style: text.labelSmall!.copyWith(
            color: style.colors.inkSubtle,
            fontWeight: FontWeight.w600,
          ),
        ),
    ]);
    if (month == null) {
      return _card([
        const SkeletonBar(widthFactor: 0.45, height: 11),
        letters,
        _weeks([
          for (var i = 0; i < 7 * _loadingWeeks; i++)
            const Center(
              child: SkeletonBar(
                width: DayCircle.daySize,
                height: DayCircle.daySize,
              ),
            ),
        ]),
        const Row(
          spacing: Gap.md,
          children: [
            SkeletonBar(width: 48, height: 10),
            SkeletonBar(width: 48, height: 10),
            SkeletonBar(width: 56, height: 10),
            SkeletonBar(width: 48, height: 10),
          ],
        ),
      ]);
    }
    final first = DateTime(month.year, month.month);
    final lead = (first.weekday - firstWeekday) % 7;
    final length = DateTime(month.year, month.month + 1, 0).day;
    final count = ((lead + length) / 7).ceil() * 7;
    return _card([
      Text(
        summary!,
        style: style.data.copyWith(fontSize: 11, color: style.colors.inkMuted),
      ),
      letters,
      _weeks([
        for (var i = 0; i < count; i++)
          _day(DateTime(month.year, month.month, 1 - lead + i), month.month),
      ]),
      Wrap(
        spacing: Gap.md,
        runSpacing: Gap.sm,
        children: [
          for (final MapEntry(key: state, value: label) in legend!.entries)
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: Gap.xs,
              children: [
                DayCircle.legend(state: state),
                Text(
                  label,
                  style: text.labelSmall!.copyWith(
                    color: style.colors.inkMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
        ],
      ),
    ]);
  }

  Widget _day(DateTime day, int month) {
    final circle = Center(
      child: DayCircle(state: stateOf!(day), number: '${day.day}'),
    );
    return day.month == month
        ? circle
        : Opacity(opacity: _outsideOpacity, child: circle);
  }

  Widget _card(List<Widget> children) => CardFrame(
    child: Padding(
      padding: const EdgeInsets.all(Gap.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Gap.sm,
        children: children,
      ),
    ),
  );

  static Widget _week(List<Widget> cells) => Row(
    spacing: Gap.xs,
    children: [for (final cell in cells) Expanded(child: cell)],
  );

  static Widget _weeks(List<Widget> cells) => Column(
    spacing: Gap.sm,
    children: [
      for (var i = 0; i < cells.length; i += 7) _week(cells.sublist(i, i + 7)),
    ],
  );
}
