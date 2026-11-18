import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import 'card_frame.dart';
import 'error_line.dart';
import 'tap_band.dart';
import 'skeleton.dart';

/// A card for one section of a page: the [title], a [detail] in data
/// ink-muted and a chevron; the whole card opens the section's page.
/// [SectionCard.plain] only holds its content.
class SectionCard extends StatelessWidget {
  /// Filled: [child] holds the content (BandBars, rows).
  const SectionCard({
    super.key,
    required this.title,
    this.detail,
    required this.onTap,
    required Widget this.child,
  }) : _state = _State.filled,
       message = null,
       onRetry = null,
       retryLabel = null,
       tag = null,
       note = null,
       actionLabel = null,
       onAction = null;

  /// Shimmering skeleton bars while the content loads.
  const SectionCard.loading({
    super.key,
    required this.title,
    required this.onTap,
  }) : _state = _State.loading,
       detail = null,
       child = null,
       message = null,
       onRetry = null,
       retryLabel = null,
       tag = null,
       note = null,
       actionLabel = null,
       onAction = null;

  /// Loading failed: [message] in danger and an outline Retry.
  const SectionCard.error({
    super.key,
    required this.title,
    required this.onTap,
    required String this.message,
    required VoidCallback this.onRetry,
    required String this.retryLabel,
  }) : _state = _State.error,
       detail = null,
       child = null,
       tag = null,
       note = null,
       actionLabel = null,
       onAction = null;

  /// Nothing yet: one muted [message].
  const SectionCard.empty({
    super.key,
    required this.title,
    required this.onTap,
    required String this.message,
  }) : _state = _State.empty,
       detail = null,
       child = null,
       onRetry = null,
       retryLabel = null,
       tag = null,
       note = null,
       actionLabel = null,
       onAction = null;

  /// Premium: the Premium [tag] (Tags) before the chevron and one muted
  /// [message]; [onTap] opens the paywall.
  const SectionCard.locked({
    super.key,
    required this.title,
    required this.onTap,
    required Widget this.tag,
    required String this.message,
  }) : _state = _State.locked,
       detail = null,
       child = null,
       onRetry = null,
       retryLabel = null,
       note = null,
       actionLabel = null,
       onAction = null;

  /// The [title] over [child], no chevron and no tap; an optional text
  /// action in accent ([actionLabel], such as "Edit") ends the header.
  /// Without [child] the card is the header alone. A [note] after the
  /// title says how to read the content; it is drawn whole, wrapping
  /// rather than cut.
  const SectionCard.plain({
    super.key,
    required this.title,
    this.note,
    this.child,
    this.actionLabel,
    this.onAction,
  }) : assert((actionLabel == null) == (onAction == null)),
       _state = _State.filled,
       onTap = null,
       detail = null,
       message = null,
       onRetry = null,
       retryLabel = null,
       tag = null;

  final String title;
  final String? detail;
  final String? note;
  final VoidCallback? onTap;
  final Widget? child;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final Widget? tag;
  final String? actionLabel;
  final VoidCallback? onAction;
  final _State _state;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final Widget? body = switch (_state) {
      _State.filled => child,
      _State.loading => const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.sm,
        children: [
          SkeletonBar(widthFactor: 0.8, height: 10),
          SkeletonBar(widthFactor: 0.55, height: 10),
        ],
      ),
      _State.error => ErrorLine(
        message: message!,
        retryLabel: retryLabel!,
        onRetry: onRetry!,
      ),
      _State.empty || _State.locked => Text(message!, style: text.bodySmall),
    };
    final action = actionLabel == null ? null : TapBandLink();
    Widget card = Padding(
      padding: const EdgeInsets.all(Gap.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Gap.md,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final titleText = Text(title, style: text.titleMedium);
              final trailing = [
                if (note case final note?)
                  Expanded(
                    child: Text(
                      note,
                      textAlign: TextAlign.end,
                      style: text.labelMedium!.copyWith(
                        fontWeight: FontWeight.w400,
                        color: colors.inkMuted,
                      ),
                    ),
                  ),
                if (detail != null)
                  // A long detail ends in an ellipsis at half the header.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth / 2,
                    ),
                    child: Text(
                      detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style.data.copyWith(color: colors.inkMuted),
                    ),
                  ),
                ?tag,
                if (actionLabel case final label?)
                  TapBandTarget(
                    link: action!,
                    child: Semantics(
                      button: true,
                      child: GestureDetector(
                        onTap: onAction,
                        child: Text(
                          label,
                          style: text.labelLarge!.copyWith(
                            color: colors.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (onTap != null)
                  ForgeIcon(
                    ForgeIcons.chevronRight,
                    size: 18,
                    color: colors.inkMuted,
                  ),
              ];
              if (trailing.isEmpty) return titleText;
              return _Header(
                // The note is drawn whole, so the title keeps at most half.
                halfTitle: note != null,
                textDirection: Directionality.of(context),
                children: [
                  titleText,
                  Row(
                    mainAxisSize: note != null
                        ? MainAxisSize.max
                        : MainAxisSize.min,
                    spacing: Gap.sm,
                    children: trailing,
                  ),
                ],
              );
            },
          ),
          ?body,
        ],
      ),
    );
    if (action != null) card = TapBandArea(links: [action], child: card);
    return CardFrame(
      child: onTap == null ? card : InkWell(onTap: onTap, child: card),
    );
  }
}

enum _State { filled, loading, error, empty, locked }

/// A card header: the title and, beside it, its trailing parts. The title
/// takes the room the trailing parts leave, or with [halfTitle] what it
/// needs up to half and the trailing parts the rest. When a word of the
/// title would not fit there (large text), the trailing parts go under
/// the title, at the end.
class _Header extends MultiChildRenderObjectWidget {
  const _Header({
    required this.halfTitle,
    required this.textDirection,
    required super.children,
  });

  final bool halfTitle;
  final TextDirection textDirection;

  @override
  _RenderHeader createRenderObject(BuildContext context) =>
      _RenderHeader(halfTitle, textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderHeader renderObject) =>
      renderObject
        ..halfTitle = halfTitle
        ..textDirection = textDirection;
}

class _HeaderParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderHeader extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _HeaderParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _HeaderParentData> {
  _RenderHeader(this._halfTitle, this._textDirection);

  static const double _gap = Gap.sm;
  static const double _stackGap = Gap.xs;

  bool _halfTitle;
  set halfTitle(bool value) {
    if (value == _halfTitle) return;
    _halfTitle = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _HeaderParentData) {
      child.parentData = _HeaderParentData();
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, ChildLayoutHelper.dryLayoutChild);

  @override
  void performLayout() {
    size = _layout(constraints, ChildLayoutHelper.layoutChild, place: true);
  }

  Size _layout(
    BoxConstraints constraints,
    ChildLayouter layoutChild, {
    bool place = false,
  }) {
    final title = firstChild!;
    final trailing = childAfter(title)!;
    final width = constraints.maxWidth;
    final titleWord = title.getMinIntrinsicWidth(double.infinity);
    final Size titleSize;
    final Size trailingSize;
    final bool stacked;
    if (_halfTitle) {
      stacked = titleWord > width / 2;
      titleSize = layoutChild(
        title,
        BoxConstraints(maxWidth: stacked ? width : width / 2),
      );
      trailingSize = layoutChild(
        trailing,
        BoxConstraints.tightFor(
          width: stacked ? width : math.max(0, width - titleSize.width - _gap),
        ),
      );
    } else {
      trailingSize = layoutChild(trailing, BoxConstraints(maxWidth: width));
      final room = math.max(0.0, width - trailingSize.width - _gap);
      stacked = titleWord > room;
      titleSize = layoutChild(
        title,
        BoxConstraints.tightFor(width: stacked ? width : room),
      );
    }
    final height = stacked
        ? titleSize.height + _stackGap + trailingSize.height
        : math.max(titleSize.height, trailingSize.height);
    if (place) {
      final rtl = _textDirection == TextDirection.rtl;
      (title.parentData! as _HeaderParentData).offset = Offset(
        rtl ? width - titleSize.width : 0,
        stacked ? 0 : (height - titleSize.height) / 2,
      );
      (trailing.parentData! as _HeaderParentData).offset = Offset(
        rtl ? 0 : width - trailingSize.width,
        stacked
            ? titleSize.height + _stackGap
            : (height - trailingSize.height) / 2,
      );
    }
    return constraints.constrain(Size(width, height));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
