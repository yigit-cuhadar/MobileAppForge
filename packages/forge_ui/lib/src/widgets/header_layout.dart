import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../spacing.dart';

/// A header of two children: a title and, [gap] after it, its trailing
/// parts, centred on each other. The title takes the room the trailing
/// parts leave, or with [halfTitle] what it needs up to half and the
/// trailing parts the rest. When a word of the title would not fit there
/// (large text), the trailing parts go under the title, at the end.
class HeaderLayout extends MultiChildRenderObjectWidget {
  const HeaderLayout({
    super.key,
    this.halfTitle = false,
    required this.gap,
    required super.children,
  }) : assert(children.length == 2);

  final bool halfTitle;
  final double gap;

  @override
  RenderHeaderLayout createRenderObject(BuildContext context) =>
      RenderHeaderLayout(halfTitle, gap, Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    RenderHeaderLayout renderObject,
  ) => renderObject
    ..halfTitle = halfTitle
    ..gap = gap
    ..textDirection = Directionality.of(context);
}

class _HeaderParentData extends ContainerBoxParentData<RenderBox> {}

class RenderHeaderLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _HeaderParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _HeaderParentData> {
  RenderHeaderLayout(this._halfTitle, this._gap, this._textDirection);

  static const double _stackGap = Gap.xs;

  bool _halfTitle;
  set halfTitle(bool value) {
    if (value == _halfTitle) return;
    _halfTitle = value;
    markNeedsLayout();
  }

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
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
    final size = constraints.constrain(
      Size(
        width,
        stacked
            ? titleSize.height + _stackGap + trailingSize.height
            : math.max(titleSize.height, trailingSize.height),
      ),
    );
    if (place) {
      final rtl = _textDirection == TextDirection.rtl;
      // Stacked, the pair is centred; side by side, each child is.
      final top = stacked
          ? (size.height - titleSize.height - _stackGap - trailingSize.height) /
                2
          : 0.0;
      (title.parentData! as _HeaderParentData).offset = Offset(
        rtl ? width - titleSize.width : 0,
        stacked ? top : (size.height - titleSize.height) / 2,
      );
      (trailing.parentData! as _HeaderParentData).offset = Offset(
        rtl ? 0 : width - trailingSize.width,
        stacked
            ? top + titleSize.height + _stackGap
            : (size.height - trailingSize.height) / 2,
      );
    }
    return size;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
