import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_palette.dart';
import '../theme/forge_style.dart';
import 'busy_ring.dart';
import 'card_frame.dart';
import 'skeleton.dart';

/// [ListRow]s in one card, a 1px line between each two.
class ListRowCard extends StatelessWidget {
  const ListRowCard({super.key, required this.children, this.onReorder});

  final List<Widget> children;

  /// Makes the rows reorderable by their [ListRowDragHandle]s; each row
  /// needs a key. Reports the row moved from one index to another, with
  /// `to` counted after the row was taken out.
  final void Function(int from, int to)? onReorder;

  @override
  Widget build(BuildContext context) {
    final onReorder = this.onReorder;
    if (onReorder == null) {
      return CardFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, row) in children.indexed) ...[
              if (i > 0) const Divider(),
              row,
            ],
          ],
        ),
      );
    }
    final line = BorderSide(color: ForgeStyle.of(context).colors.line);
    return CardFrame(
      child: ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        onReorderItem: onReorder,
        children: [
          for (final (i, row) in children.indexed)
            DecoratedBox(
              key: row.key,
              decoration: BoxDecoration(
                border: i == 0 ? null : Border(top: line),
              ),
              child: row,
            ),
        ],
      ),
    );
  }
}

/// What closes a row: a chevron for a row that opens a page, open-in-new
/// for an external link.
enum ListRowEnd { none, chevron, external }

/// One row of a [ListRowCard]: an optional [leading] part, the [title] with
/// a [detail] line under it, the [value] in ink-muted, a [trailing] part
/// (a Tag, Button, Switch or TextField) and the [end] mark.
class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required String this.title,
    this.detail,
    this.error,
    this.leading,
    this.value,
    this.trailing,
    this.end = ListRowEnd.none,
    this.onTap,
    this.onInfo,
    this.checked,
    this.destructive = false,
    this.missing = false,
    this.locked = false,
    this.busy = false,
  }) : assert(checked == null || leading == null),
       loading = false;

  /// Keeps the row's height and shows shimmering bars where its title,
  /// detail and value will be.
  const ListRow.loading({super.key})
    : title = null,
      detail = null,
      error = null,
      leading = null,
      value = null,
      trailing = null,
      end = ListRowEnd.none,
      onTap = null,
      onInfo = null,
      checked = null,
      destructive = false,
      missing = false,
      locked = false,
      busy = false,
      loading = true;

  final String? title;
  final String? detail;

  /// A danger line under the title, in place of [detail]: what is missing
  /// or what went wrong.
  final String? error;

  /// A [ListRowDateBox], a [ListRowDragHandle] or another part in front.
  final Widget? leading;
  final String? value;
  final Widget? trailing;
  final ListRowEnd end;
  final VoidCallback? onTap;

  /// Shows an info icon after the title; the app opens a sheet that
  /// explains the field.
  final VoidCallback? onInfo;

  /// Puts a checkbox in front; a checked row turns accent-soft.
  final bool? checked;

  /// The title in danger: a row that deletes or ends something.
  final bool destructive;

  /// A required value that is not set: a soft danger tint and the value
  /// as a danger dash. Say what is needed in [error].
  final bool missing;

  /// Premium content: the title muted; put the Premium tag in [trailing]
  /// and open the paywall from [onTap].
  final bool locked;

  /// Work the user started on this row (unlocking): a small turning ring
  /// at the end.
  final bool busy;
  final bool loading;

  static const _minHeight = 52.0;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final text = Theme.of(context).textTheme;
    if (loading) {
      return _frame(
        const Row(
          spacing: Gap.md,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Gap.sm,
                children: [
                  SkeletonBar(widthFactor: 0.55, height: 12),
                  SkeletonBar(widthFactor: 0.35, height: 10),
                ],
              ),
            ),
            SkeletonBar(width: 40, height: 10),
          ],
        ),
      );
    }

    final on = checked ?? false;
    final titleColor = destructive
        ? colors.danger
        : locked
        ? colors.inkMuted
        : on
        ? colors.onAccentSoft
        : colors.ink;
    final detailColor = error != null
        ? colors.danger
        : locked
        ? colors.inkSubtle
        : on
        ? colors.onAccentSoft
        : colors.inkMuted;
    final line = error ?? detail;
    final leading = checked == null ? this.leading : _Checkbox(checked: on);

    Widget title = Text(
      this.title!,
      style: text.bodyMedium!.copyWith(color: titleColor),
    );
    if (onInfo != null) {
      title = Row(
        children: [
          Flexible(child: title),
          InkResponse(
            onTap: onInfo,
            radius: Gap.md,
            child: Padding(
              padding: const EdgeInsets.all(Gap.xs),
              child: ForgeIcon(
                ForgeIcons.info,
                size: 16,
                color: colors.inkMuted,
              ),
            ),
          ),
        ],
      );
    }

    final row = Row(
      spacing: Gap.md,
      children: [
        ?leading,
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              if (line != null) ...[
                const SizedBox(height: 1),
                Text(
                  line,
                  style: text.labelMedium!.copyWith(
                    fontWeight: FontWeight.w400,
                    color: detailColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (missing)
          Text('—', style: text.bodySmall!.copyWith(color: colors.danger))
        else if (value != null)
          Text(value!, style: text.bodySmall),
        ?trailing,
        if (busy)
          Opacity(
            opacity: 0.8,
            child: BusyRing(
              size: 16,
              stroke: 2,
              sweep: 0.75,
              color: colors.inkMuted,
            ),
          ),
        ?_endMark(colors),
      ],
    );

    final tint = on
        ? colors.accentSoft
        : missing
        ? Color.lerp(colors.surface, colors.danger, 0.08)
        : null;
    return MergeSemantics(
      child: Semantics(
        checked: checked,
        child: Material(
          type: tint == null ? MaterialType.transparency : MaterialType.canvas,
          color: tint,
          child: InkWell(onTap: onTap, child: _frame(row)),
        ),
      ),
    );
  }

  Widget? _endMark(ForgePalette colors) => switch (end) {
    ListRowEnd.none => null,
    ListRowEnd.chevron => ForgeIcon(
      ForgeIcons.chevronRight,
      size: 18,
      color: colors.inkMuted,
    ),
    ListRowEnd.external => ForgeIcon(
      ForgeIcons.openInNew,
      size: 16,
      color: colors.inkMuted,
    ),
  };

  Widget _frame(Widget child) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: _minHeight),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
      child: child,
    ),
  );
}

/// A row's leading date: the weekday over the day of the month, filled
/// accent for [today].
class ListRowDateBox extends StatelessWidget {
  const ListRowDateBox({
    super.key,
    required this.weekday,
    required this.day,
    this.today = false,
  });

  final String weekday;
  final String day;
  final bool today;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final ink = today ? style.colors.onAccent : style.colors.ink;
    return Container(
      width: 40,
      height: 44,
      decoration: BoxDecoration(
        color: today ? style.colors.accent : style.colors.surfaceSunken,
        borderRadius: BorderRadius.circular(style.radii.sm),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            weekday,
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: ink.withValues(alpha: 0.8),
            ),
          ),
          Text(
            day,
            style: style.data.copyWith(fontSize: 16, height: 1.25, color: ink),
          ),
        ],
      ),
    );
  }
}

/// The leading handle of a row in a reorderable list; dragging it moves
/// the row at [index].
class ListRowDragHandle extends StatelessWidget {
  const ListRowDragHandle({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) => ReorderableDragStartListener(
    index: index,
    child: ForgeIcon(
      ForgeIcons.dragIndicator,
      size: 18,
      color: ForgeStyle.of(context).colors.inkSubtle,
    ),
  );
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: checked ? colors.accent : null,
        borderRadius: BorderRadius.circular(5),
        border: checked
            ? null
            : Border.all(color: colors.lineStrong, width: 1.5),
      ),
      child: checked
          ? ForgeIcon(ForgeIcons.check, size: 14, color: colors.onAccent)
          : null,
    );
  }
}
