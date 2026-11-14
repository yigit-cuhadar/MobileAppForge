import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_palette.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';
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
  final bool loading;
  final int _skeleton;

  static const _minHeight = 52.0;

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
    final info = onInfo == null ? null : _BandLink();
    final handle = this.leading is ListRowDragHandle ? _BandLink() : null;
    final leading = checked != null
        ? _Checkbox(checked: on)
        : handle != null
        ? _BandTarget(link: handle, child: this.leading!)
        : this.leading;

    final prominent = this.leading is ListRowDateBox || onInfo != null;
    Widget title = Text(
      this.title!,
      style: (prominent ? text.titleMedium! : text.bodyMedium!).copyWith(
        color: titleColor,
      ),
    );
    if (onInfo != null) {
      title = Row(
        spacing: Gap.xs,
        children: [
          Flexible(child: title),
          _BandTarget(
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

    final row = Row(
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
    Widget result = Material(
      type: tint == null ? MaterialType.transparency : MaterialType.canvas,
      color: tint,
      child: InkWell(
        onTap: onTap,
        child: info == null && handle == null
            ? _frame(row)
            : _BandArea(links: [?info, ?handle], child: _frame(row)),
      ),
    );
    if (checked != null) {
      result = MergeSemantics(
        child: Semantics(checked: checked, child: result),
      );
    }
    return result;
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

/// Lets the row find a small control (the info icon, the drag handle)
/// when hit-testing.
class _BandLink {
  RenderBox? target;
}

/// Marks a small control for its row's [_BandArea].
class _BandTarget extends SingleChildRenderObjectWidget {
  const _BandTarget({required this.link, required super.child});

  final _BandLink link;

  @override
  RenderProxyBox createRenderObject(BuildContext context) =>
      _RenderBandTarget(link);

  @override
  void updateRenderObject(BuildContext context, _RenderBandTarget target) =>
      target.link = link;
}

class _RenderBandTarget extends RenderProxyBox {
  _RenderBandTarget(_BandLink link) {
    this.link = link;
  }

  set link(_BandLink link) => link.target = this;
}

/// Sends touches within a tap-min square around each linked control to
/// that control, though it is drawn smaller and the layout stays as drawn.
class _BandArea extends SingleChildRenderObjectWidget {
  const _BandArea({required this.links, required super.child});

  final List<_BandLink> links;

  @override
  RenderProxyBox createRenderObject(BuildContext context) =>
      _RenderBandArea(links);

  @override
  void updateRenderObject(BuildContext context, _RenderBandArea area) =>
      area.links = links;
}

class _RenderBandArea extends RenderProxyBox {
  _RenderBandArea(this.links);

  List<_BandLink> links;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (size.contains(position)) {
      for (final link in links) {
        final target = link.target;
        if (target == null || !target.attached || !target.hasSize) continue;
        final local = target.globalToLocal(localToGlobal(position));
        final centre = target.size.center(Offset.zero);
        final area = Rect.fromCenter(
          center: centre,
          width: max(ForgeTheme.tapMin, target.size.width),
          height: max(ForgeTheme.tapMin, target.size.height),
        );
        if (area.contains(local)) {
          target.hitTest(result, position: centre);
          result.add(BoxHitTestEntry(this, position));
          return true;
        }
      }
    }
    return super.hitTest(result, position: position);
  }
}
