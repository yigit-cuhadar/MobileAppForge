import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';
import 'card_frame.dart';
import 'day_circle.dart';
import 'error_line.dart';
import 'forge_button.dart';
import 'forge_dialog.dart';
import 'skeleton.dart';

/// A month of day circles in a card: an optional [summary] line, the [weekdays]
/// letters, the weeks that hold the month and a [legend]. Days of the
/// weeks outside the month show at 35%. A tap on a day calls [onDayTap];
/// the [selected] day carries the selected ring. A PeriodSelector above
/// the card changes the month.
class MonthGrid extends StatelessWidget {
  const MonthGrid({
    super.key,
    required DateTime this.month,
    required this.firstWeekday,
    required this.weekdays,
    required DayState Function(DateTime day) this.stateOf,
    this.summary,
    required Map<DayState, String> this.legend,
    this.selected,
    this.onDayTap,
  }) : message = null,
       retryLabel = null,
       onRetry = null;

  /// The weekday letters stay; the summary, days and legend shimmer.
  const MonthGrid.loading({super.key, required this.weekdays})
    : month = null,
      firstWeekday = DateTime.monday,
      stateOf = null,
      summary = null,
      legend = null,
      selected = null,
      onDayTap = null,
      message = null,
      retryLabel = null,
      onRetry = null;

  /// Loading failed: the weekday letters stay, and in place of the days
  /// the [message] in danger with an outline Retry on one line.
  const MonthGrid.error({
    super.key,
    required this.weekdays,
    required String this.message,
    required String this.retryLabel,
    required VoidCallback this.onRetry,
  }) : month = null,
       firstWeekday = DateTime.monday,
       stateOf = null,
       summary = null,
       legend = null,
       selected = null,
       onDayTap = null;

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

  /// The chosen day, if any.
  final DateTime? selected;
  final ValueChanged<DateTime>? onDayTap;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;

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
    if (message case final message?) {
      return _card([
        letters,
        ErrorLine(message: message, retryLabel: retryLabel!, onRetry: onRetry!),
      ]);
    }
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
      if (summary case final summary?)
        Text(
          summary,
          style: style.data.copyWith(
            fontSize: 11,
            color: style.colors.inkMuted,
          ),
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
    final selected = this.selected;
    final isSelected =
        selected != null &&
        selected.year == day.year &&
        selected.month == day.month &&
        selected.day == day.day;
    Widget circle = Center(
      child: DayCircle(
        state: stateOf!(day),
        number: '${day.day}',
        selected: isSelected,
      ),
    );
    if (day.month != month) {
      circle = Opacity(opacity: _outsideOpacity, child: circle);
    }
    final onDayTap = this.onDayTap;
    if (onDayTap == null) return circle;
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onDayTap(day),
        child: circle,
      ),
    );
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

  static Widget _weeks(List<Widget> cells, {double spacing = Gap.sm}) => Column(
    spacing: spacing,
    children: [
      for (var i = 0; i < cells.length; i += 7) _week(cells.sublist(i, i + 7)),
    ],
  );
}

/// Shows a [ForgeDatePicker] over a scrim. Returns the picked day, or null
/// after Cancel or a tap outside.
Future<DateTime?> showForgeDatePicker({
  required BuildContext context,
  required ForgeDatePicker picker,
}) => showDialog<DateTime>(context: context, builder: (_) => picker);

/// A centred dialog to pick a day: the [title] ("Select date") over the
/// chosen day as a headline, the month between previous and next arrows,
/// the month's days as [MonthGrid] draws them with the chosen day filled
/// accent, then the [okLabel] button over the [cancelLabel] one. Days after
/// [lastDate] are line-strong and cannot be picked, and the next arrow
/// fades once no later month holds a day to pick. Tapping a day of the
/// month before or after picks it and shows its month.
class ForgeDatePicker extends StatefulWidget {
  const ForgeDatePicker({
    super.key,
    required this.title,
    required this.initial,
    required this.lastDate,
    required this.firstWeekday,
    required this.weekdays,
    required this.okLabel,
    required this.cancelLabel,
  });

  final String title;
  final DateTime initial;
  final DateTime lastDate;

  /// The week's first day, [DateTime.monday] to [DateTime.sunday].
  final int firstWeekday;

  /// Seven letters, from [firstWeekday] on.
  final List<String> weekdays;
  final String okLabel;
  final String cancelLabel;

  @override
  State<ForgeDatePicker> createState() => _ForgeDatePickerState();
}

class _ForgeDatePickerState extends State<ForgeDatePicker> {
  late DateTime _selected = DateUtils.dateOnly(widget.initial);
  late DateTime _month = DateTime(_selected.year, _selected.month);

  DateTime get _last => DateUtils.dateOnly(widget.lastDate);

  void _pick(DateTime day) => setState(() {
    _selected = day;
    _month = DateTime(day.year, day.month);
  });

  void _show(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final words = MaterialLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final next = DateTime(_month.year, _month.month + 1);
    final first = DateTime(_month.year, _month.month);
    final lead = (first.weekday - widget.firstWeekday) % 7;
    final length = DateTime(_month.year, _month.month + 1, 0).day;
    final count = ((lead + length) / 7).ceil() * 7;
    return Dialog(
      insetPadding: const EdgeInsets.all(Gap.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ForgeDialog.maxWidth),
        child: Semantics(
          namesRoute: true,
          scopesRoute: true,
          explicitChildNodes: true,
          label: widget.title,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.md,
              vertical: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      widget.title,
                      style: text.labelMedium!.copyWith(
                        color: colors.inkMuted,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      words.formatMediumDate(_selected),
                      style: text.titleLarge!.copyWith(
                        fontSize: 22,
                        height: 28 / 22,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _MonthArrow(
                      icon: rtl
                          ? ForgeIcons.chevronRight
                          : ForgeIcons.chevronLeft,
                      label: words.previousMonthTooltip,
                      onTap: () => _show(-1),
                    ),
                    Expanded(
                      child: Text(
                        words.formatMonthYear(_month),
                        textAlign: TextAlign.center,
                        style: text.titleMedium,
                      ),
                    ),
                    _MonthArrow(
                      icon: rtl
                          ? ForgeIcons.chevronLeft
                          : ForgeIcons.chevronRight,
                      label: words.nextMonthTooltip,
                      onTap: next.isAfter(_last) ? null : () => _show(1),
                    ),
                  ],
                ),
                MonthGrid._week([
                  for (final letter in widget.weekdays)
                    Text(
                      letter,
                      textAlign: TextAlign.center,
                      style: text.labelSmall!.copyWith(
                        color: colors.inkSubtle,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ]),
                MonthGrid._weeks(spacing: Gap.xs, [
                  for (var i = 0; i < count; i++)
                    _day(DateTime(_month.year, _month.month, 1 - lead + i)),
                ]),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: Gap.sm,
                  children: [
                    ForgeButton(
                      label: widget.okLabel,
                      onPressed: () => Navigator.pop(context, _selected),
                    ),
                    ForgeButton(
                      label: widget.cancelLabel,
                      variant: ForgeButtonVariant.secondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _day(DateTime day) {
    final selected = DateUtils.isSameDay(day, _selected);
    final disabled = day.isAfter(_last);
    Widget circle = Center(
      child: DayCircle(
        state: selected ? DayState.done : DayState.none,
        number: '${day.day}',
        disabled: disabled,
      ),
    );
    if (day.month != _month.month) {
      circle = Opacity(opacity: MonthGrid._outsideOpacity, child: circle);
    }
    return Semantics(
      button: true,
      selected: selected,
      enabled: !disabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled ? null : () => _pick(day),
        child: circle,
      ),
    );
  }
}

/// A month arrow: ink-muted, line-strong when [onTap] is null.
class _MonthArrow extends StatelessWidget {
  const _MonthArrow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final ForgeIconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: ForgeTheme.tapMin,
          child: Center(
            child: ForgeIcon(
              icon,
              size: 20,
              color: onTap == null ? colors.lineStrong : colors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}
