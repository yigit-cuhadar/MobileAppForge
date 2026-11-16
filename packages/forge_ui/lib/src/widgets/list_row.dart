import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_palette.dart';
import '../theme/forge_style.dart';
import 'busy_ring.dart';
import 'card_frame.dart';
import 'chart_paint.dart';
import 'day_circle.dart';
import 'skeleton.dart';
import 'tap_band.dart';

/// [ListRow]s in one card, a 1px line between each two.
class ListRowCard extends StatelessWidget {
  const ListRowCard({super.key, required this.children, this.onReorder})
    : itemCount = 0,
      itemBuilder = null;

  /// The lazy form for a long list: a sliver for a [CustomScrollView] that
  /// builds each of its [itemCount] rows only as it scrolls into view.
  const ListRowCard.sliver({
    super.key,
    required this.itemCount,
    required IndexedWidgetBuilder this.itemBuilder,
  }) : children = const [],
       onReorder = null;

  final List<Widget> children;

  /// Makes the rows reorderable by their [ListRowDragHandle]s; each row
  /// needs a key. Reports the row moved from one index to another, with
  /// `to` counted after the row was taken out.
  final void Function(int from, int to)? onReorder;
  final int itemCount;
  final IndexedWidgetBuilder? itemBuilder;

  @override
  Widget build(BuildContext context) {
    final itemBuilder = this.itemBuilder;
    if (itemBuilder != null) return _sliver(context, itemBuilder);
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
        // Lifted flat, like every Forge card: no shadow.
        proxyDecorator: (row, index, animation) =>
            Material(color: ForgeStyle.of(context).colors.surface, child: row),
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

  /// The card drawn as [CardFrame] draws it, around rows built on demand.
  Widget _sliver(BuildContext context, IndexedWidgetBuilder itemBuilder) {
    final style = ForgeStyle.of(context);
    final radius = Radius.circular(style.radii.lg);
    Widget row(BuildContext context, int i) {
      final row = itemBuilder(context, i);
      if (i > 0 && i < itemCount - 1) return row;
      // Tinted first and last rows keep inside the rounded corners.
      return ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: i == 0 ? radius : Radius.zero,
          bottom: i == itemCount - 1 ? radius : Radius.zero,
        ),
        child: row,
      );
    }

    return DecoratedSliver(
      decoration: BoxDecoration(
        color: style.colors.surface,
        borderRadius: BorderRadius.all(radius),
      ),
      sliver: DecoratedSliver(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(radius),
          border: style.cardBorder == 0
              ? null
              : Border.all(color: style.colors.line, width: style.cardBorder),
        ),
        sliver: SliverList.separated(
          itemCount: itemCount,
          itemBuilder: row,
          separatorBuilder: (_, _) => const Divider(),
        ),
      ),
    );
  }
}

/// What closes a row: a chevron for a row that opens a page, open-in-new
/// for an external link.
enum ListRowEnd { none, chevron, external }

/// One row of a [ListRowCard]: an optional [leading] part, the [title] with
/// a [detail] line under it, the [value] in ink-muted, a [trailing] part
/// (a Tag, Button, Switch or TextField) and the [end] mark. A row with a
/// [ListRowDateBox] or an info icon has a title-style title and sits
/// tighter.
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
    this.infoLabel,
    this.checked,
    this.destructive = false,
    this.missing = false,
    this.locked = false,
    this.busy = false,
    this.disabled = false,
    this.muted = false,
    this.dataTitle = false,
    this.dataValue = false,
  }) : assert(checked == null || leading == null),
       assert(
         (onInfo == null) == (infoLabel == null),
         'Give the info icon a label and an action together.',
       ),
       loading = false,
       _skeleton = 0;

  /// Keeps the row's height and shows shimmering bars where its title,
  /// detail and value will be; their lengths vary with the row's [index].
  const ListRow.loading({super.key, int index = 0})
    : _skeleton = index % 3,
      title = null,
      detail = null,
      error = null,
      leading = null,
      value = null,
      trailing = null,
      end = ListRowEnd.none,
      onTap = null,
      onInfo = null,
      infoLabel = null,
      checked = null,
      destructive = false,
      missing = false,
      locked = false,
      busy = false,
      disabled = false,
      muted = false,
      dataTitle = false,
      dataValue = false,
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

  /// What screen readers call the info icon ("About this field").
  final String? infoLabel;

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

  /// Cannot be picked now (a full item): its text and end mark in
  /// line-strong, no tap.
  final bool disabled;

  /// The title in ink-muted: an entry that is gone or set aside, still
  /// listed.
  final bool muted;

  /// The title in the data font, for a figure such as a set ("80 × 8").
  final bool dataTitle;

  /// The value in the data font, for a figure such as a record.
  final bool dataValue;
  final bool loading;
  final int _skeleton;

  static const _minHeight = 52.0;
  static const _flushMinHeight = 40.0;

  // Title and detail bar widths of loading rows, in turn.
  static const _skeletons = [(0.55, 0.35), (0.45, 0.30), (0.60, 0.40)];

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final text = Theme.of(context).textTheme;
    if (loading) {
      final (titleWidth, detailWidth) = _skeletons[_skeleton];
      return _frame(
        Row(
          spacing: Gap.md,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Gap.sm,
                children: [
                  SkeletonBar(widthFactor: titleWidth, height: 12),
                  SkeletonBar(widthFactor: detailWidth, height: 10),
                ],
              ),
            ),
            const SkeletonBar(width: 40, height: 10),
          ],
        ),
      );
    }

    final flush = ListRowFlush._of(context);
    final on = checked ?? false;
    // A checked row turns accent-soft, except flush in a dialog's list.
    final tinted = on && !flush;
    final titleColor = disabled
        ? colors.lineStrong
        : destructive
        ? colors.danger
        : locked || muted
        ? colors.inkMuted
        : tinted
        ? colors.onAccentSoft
        : colors.ink;
    final detailColor = disabled
        ? colors.lineStrong
        : error != null
        ? colors.danger
        : locked
        ? colors.inkSubtle
        : tinted
        ? colors.onAccentSoft
        : colors.inkMuted;
    final line = error ?? detail;
    final info = onInfo == null ? null : TapBandLink();
    final handle = this.leading is ListRowDragHandle ? TapBandLink() : null;
    final leading = checked != null
        ? _Checkbox(checked: on)
        : handle != null
        ? TapBandTarget(link: handle, child: this.leading!)
        : this.leading;

    final prominent = this.leading is ListRowDateBox || onInfo != null;
    final data = ForgeStyle.of(context).data;
    final titleStyle = prominent ? text.titleMedium! : text.bodyMedium!;
    Widget title = Text(
      this.title!,
      style: (dataTitle ? _data(data, titleStyle) : titleStyle).copyWith(
        color: titleColor,
      ),
    );
    if (onInfo != null) {
      title = Row(
        spacing: Gap.xs,
        children: [
          Flexible(child: title),
          TapBandTarget(
            link: info!,
            child: Semantics(
              container: true,
              button: true,
              label: infoLabel,
              child: GestureDetector(
                onTap: onInfo,
                child: ForgeIcon(
                  ForgeIcons.info,
                  size: 16,
                  color: colors.inkMuted,
                ),
              ),
            ),
          ),
        ],
      );
    }

    Widget rowOf(double rowWidth) => Row(
      spacing: prominent ? Gap.sm : Gap.md,
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
          // At most half the row, so a long value wraps under large text
          // while a short one keeps its natural width at the end.
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: rowWidth / 2),
            child: Text(
              value!,
              textAlign: TextAlign.end,
              style:
                  (dataValue ? _data(data, text.bodySmall!) : text.bodySmall!)
                      .copyWith(color: disabled ? colors.lineStrong : null),
            ),
          ),
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
    final row = LayoutBuilder(
      builder: (context, constraints) => rowOf(constraints.maxWidth),
    );

    final tint = tinted
        ? colors.accentSoft
        : missing
        ? Color.lerp(colors.surface, colors.danger, 0.08)
        : null;
    Widget result = Material(
      type: tint == null ? MaterialType.transparency : MaterialType.canvas,
      color: tint,
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: info == null && handle == null
            ? _frame(row, flush: flush)
            : TapBandArea(
                links: [?info, ?handle],
                child: _frame(row, flush: flush),
              ),
      ),
    );
    if (checked != null || disabled) {
      result = MergeSemantics(
        child: Semantics(
          checked: checked,
          enabled: disabled ? false : null,
          child: result,
        ),
      );
    }
    return result;
  }

  /// The data font at the size and weight of [role].
  static TextStyle _data(TextStyle data, TextStyle role) => data.copyWith(
    fontSize: role.fontSize,
    height: role.height,
    fontWeight: role.fontWeight,
    color: role.color,
  );

  Widget? _endMark(ForgePalette colors) {
    final color = disabled ? colors.lineStrong : colors.inkMuted;
    return switch (end) {
      ListRowEnd.none => null,
      ListRowEnd.chevron => ForgeIcon(
        ForgeIcons.chevronRight,
        size: 18,
        color: color,
      ),
      ListRowEnd.external => ForgeIcon(
        ForgeIcons.openInNew,
        size: 16,
        color: color,
      ),
    };
  }

  Widget _frame(Widget child, {bool flush = false}) => ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: flush ? _flushMinHeight : _minHeight,
    ),
    child: Padding(
      padding: flush
          ? const EdgeInsets.symmetric(vertical: Gap.xs)
          : const EdgeInsets.symmetric(horizontal: Gap.md, vertical: Gap.sm),
      child: child,
    ),
  );
}

/// Draws the [ListRow]s under it flush: no side padding, 40px tall at
/// least, and checked rows untinted. ForgeDialog's list puts its rows in
/// one.
class ListRowFlush extends InheritedWidget {
  const ListRowFlush({super.key, required super.child});

  static bool _of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ListRowFlush>() != null;

  @override
  bool updateShouldNotify(ListRowFlush oldWidget) => false;
}

/// A row's leading date: the weekday over the day of the month, marked as
/// the calendar's day circles are: plain on surface-sunken, done filled
/// accent, missed a danger outline, planned a dashed line-strong outline,
/// today a 2.5px ink ring.
class ListRowDateBox extends StatelessWidget {
  const ListRowDateBox({
    super.key,
    required this.weekday,
    required this.day,
    this.state = DayState.none,
  }) : assert(
         state != DayState.light && state != DayState.todayDone,
         'The date box draws none, done, missed, planned and today.',
       );

  final String weekday;
  final String day;
  final DayState state;

  static const _width = 1.5;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final p = style.colors;
    final radius = style.radii.sm;
    final (fill, ink, ring, ringWidth) = switch (state) {
      DayState.done => (p.accent, p.onAccent, null, 0.0),
      DayState.missed => (p.surface, p.danger, p.danger, _width),
      DayState.planned => (p.surface, p.ink, null, 0.0),
      DayState.today => (p.surface, p.ink, p.ink, 2.5),
      _ => (p.surfaceSunken, p.ink, null, 0.0),
    };
    final box = Container(
      width: 40,
      height: 44,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: ring == null ? null : Border.all(color: ring, width: ringWidth),
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
    if (state != DayState.planned) return box;
    return CustomPaint(
      foregroundPainter: DashedBorderPainter(
        color: p.lineStrong,
        width: _width,
        radius: radius,
      ),
      child: box,
    );
  }
}

/// The leading handle of a row in a reorderable list; dragging it, or
/// anywhere in a 44px square around it, moves the row at [index].
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
