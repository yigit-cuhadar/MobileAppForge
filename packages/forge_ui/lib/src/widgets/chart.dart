import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import 'card_frame.dart';
import 'chart_paint.dart';
import 'skeleton.dart';
import 'state_views.dart';

/// One bar of [Chart.bar]: its [label] under it and, once it has a
/// [value], the [valueLabel] above it. A bar with no value yet is a short
/// stub.
class ChartBar {
  const ChartBar({required this.label, this.value, this.valueLabel})
    : assert((value == null) == (valueLabel == null));

  final String label;
  final double? value;
  final String? valueLabel;
}

/// A chart in a card under its [title] and [detail]: a line with a dot per
/// point, or bars with their values. A goal is a dashed success line.
class Chart extends StatelessWidget {
  /// A 2px accent line with a dot per point, no grid, [startLabel] and
  /// [endLabel] under its ends. A tap rings the nearest point and shows its
  /// [pointLabel] in a dark tag above it.
  const Chart.line({
    super.key,
    required this.title,
    this.detail,
    required List<double> this.values,
    required String Function(int index) this.pointLabel,
    this.target,
    required String this.startLabel,
    required String this.endLabel,
    required String this.semanticLabel,
  }) : _state = _State.line,
       bars = null,
       current = null,
       _messageTitle = null,
       message = null,
       actions = const [],
       onRetry = null,
       retryLabel = null;

  /// Bars with their value above and their label under them; the
  /// [current] bar (today) in accent, the others in accent at 55%.
  const Chart.bar({
    super.key,
    required this.title,
    this.detail,
    required List<ChartBar> this.bars,
    this.current,
    this.target,
    required String this.semanticLabel,
  }) : _state = _State.bar,
       values = null,
       pointLabel = null,
       startLabel = null,
       endLabel = null,
       _messageTitle = null,
       message = null,
       actions = const [],
       onRetry = null,
       retryLabel = null;

  /// The title row stays; the chart and its end labels shimmer.
  const Chart.loading({super.key, required this.title, this.detail})
    : _state = _State.loading,
      values = null,
      pointLabel = null,
      startLabel = null,
      endLabel = null,
      semanticLabel = null,
      bars = null,
      current = null,
      target = null,
      _messageTitle = null,
      message = null,
      actions = const [],
      onRetry = null,
      retryLabel = null;

  /// No data yet: [emptyTitle], a [message] and up to two [actions]
  /// (Buttons) in place of the chart.
  const Chart.empty({
    super.key,
    required this.title,
    this.detail,
    required String emptyTitle,
    required String this.message,
    this.actions = const [],
  }) : _state = _State.empty,
       _messageTitle = emptyTitle,
       values = null,
       pointLabel = null,
       startLabel = null,
       endLabel = null,
       semanticLabel = null,
       bars = null,
       current = null,
       target = null,
       onRetry = null,
       retryLabel = null;

  /// Loading failed: [errorTitle] over a [message] and an outline Retry
  /// in place of the chart.
  const Chart.error({
    super.key,
    required this.title,
    this.detail,
    required String errorTitle,
    required String this.message,
    required VoidCallback this.onRetry,
    required String this.retryLabel,
  }) : _state = _State.error,
       _messageTitle = errorTitle,
       values = null,
       pointLabel = null,
       startLabel = null,
       endLabel = null,
       semanticLabel = null,
       bars = null,
       current = null,
       target = null,
       actions = const [];

  final String title;
  final String? detail;
  final List<double>? values;
  final String Function(int index)? pointLabel;

  /// The goal, on the values' scale.
  final double? target;
  final String? startLabel;
  final String? endLabel;

  /// What the chart shows, for screen readers.
  final String? semanticLabel;
  final List<ChartBar>? bars;
  final int? current;
  final String? _messageTitle;
  final String? message;
  final List<Widget> actions;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final _State _state;

  @override
  Widget build(BuildContext context) {
    final children = switch (_state) {
      _State.line => [
        _LineChart(
          values: values!,
          pointLabel: pointLabel!,
          target: target,
          semanticLabel: semanticLabel!,
        ),
        ChartEndLabels(start: startLabel!, end: endLabel!, size: 10),
      ],
      _State.bar => [
        _BarChart(
          bars: bars!,
          current: current,
          target: target,
          semanticLabel: semanticLabel!,
        ),
      ],
      _State.loading => [
        SkeletonBar(
          widthFactor: 1,
          height: 120,
          radius: ForgeStyle.of(context).radii.sm,
        ),
        const ChartEndSkeletons(width: 60),
      ],
      _State.empty => [
        EmptyView(
          icon: ForgeIcons.showChart,
          title: _messageTitle!,
          message: message!,
          actions: actions,
          compact: true,
        ),
      ],
      _State.error => [
        ErrorView(
          title: _messageTitle!,
          message: message!,
          onRetry: onRetry!,
          retryLabel: retryLabel!,
          compact: true,
        ),
      ],
    };
    return CardFrame(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Gap.sm,
          children: [
            ChartTitleRow(title: title, detail: detail),
            ...children,
          ],
        ),
      ),
    );
  }
}

enum _State { line, bar, loading, empty, error }

class _LineChart extends StatefulWidget {
  const _LineChart({
    required this.values,
    required this.pointLabel,
    required this.target,
    required this.semanticLabel,
  });

  final List<double> values;
  final String Function(int index) pointLabel;
  final double? target;
  final String semanticLabel;

  static const height = 150.0;

  /// Room at the sides and ends for the ringed dot.
  static const inset = 6.0;

  @override
  State<_LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<_LineChart> {
  int? _selected;

  @override
  void didUpdateWidget(_LineChart old) {
    super.didUpdateWidget(old);
    if (_selected != null && _selected! >= widget.values.length) {
      _selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: SizedBox(
        height: _LineChart.height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, _LineChart.height);
            final points = _points(size);
            final selected = _selected;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: points.isEmpty
                  ? null
                  : (details) => setState(
                      () => _selected = nearest([
                        for (final p in points) p.dx,
                      ], details.localPosition.dx),
                    ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LinePainter(
                        points: points,
                        targetY: _targetY(size),
                        selected: selected,
                        line: colors.accent,
                        target: colors.success,
                        surface: colors.surface,
                      ),
                    ),
                  ),
                  if (selected != null)
                    Positioned.fill(
                      child: CustomSingleChildLayout(
                        delegate: _TagLayout(points[selected]),
                        child: _Tag(widget.pointLabel(selected)),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  (double, double) _range() {
    final all = [...widget.values, ?widget.target];
    return (all.reduce(math.min), all.reduce(math.max));
  }

  List<Offset> _points(Size size) {
    final values = widget.values;
    if (values.isEmpty) return const [];
    final (min, max) = _range();
    const inset = _LineChart.inset;
    final xs = spreadX(values.length, inset, size.width - inset);
    return [
      for (final (i, v) in values.indexed)
        Offset(xs[i], scaleY(v, min, max, inset, size.height - inset)),
    ];
  }

  double? _targetY(Size size) {
    final target = widget.target;
    if (target == null || widget.values.isEmpty) return null;
    final (min, max) = _range();
    const inset = _LineChart.inset;
    return scaleY(target, min, max, inset, size.height - inset);
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({
    required this.points,
    required this.targetY,
    required this.selected,
    required this.line,
    required this.target,
    required this.surface,
  });

  final List<Offset> points;
  final double? targetY;
  final int? selected;
  final Color line;
  final Color target;
  final Color surface;

  static const dot = 3.0;
  static const selectedDot = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final targetY = this.targetY;
    if (targetY != null) {
      canvas.drawPath(
        dashed(
          Path()
            ..moveTo(0, targetY)
            ..lineTo(size.width, targetY),
          4,
          4,
        ),
        Paint()
          ..color = target
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
    if (points.isEmpty) return;
    final stroke = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(Path()..addPolygon(points, false), stroke);
    final fill = Paint()..color = line;
    for (final (i, p) in points.indexed) {
      if (i == selected) {
        canvas.drawCircle(p, selectedDot, Paint()..color = surface);
        canvas.drawCircle(p, selectedDot, stroke);
      } else {
        canvas.drawCircle(p, dot, fill);
        canvas.drawCircle(p, dot, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points ||
      old.targetY != targetY ||
      old.selected != selected ||
      old.line != line ||
      old.target != target ||
      old.surface != surface;
}

/// Places the tag centred above [point], inside the chart's width; below
/// the point when there is no room above.
class _TagLayout extends SingleChildLayoutDelegate {
  const _TagLayout(this.point);

  final Offset point;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size child) {
    final x = (point.dx - child.width / 2)
        .clamp(0.0, math.max(0.0, size.width - child.width))
        .toDouble();
    final above = point.dy - _LinePainter.selectedDot - Gap.xs - child.height;
    final y = above >= 0 ? above : point.dy + _LinePainter.selectedDot + Gap.xs;
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_TagLayout old) => old.point != point;
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
      decoration: BoxDecoration(
        color: style.colors.ink,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          maxLines: 1,
          style: style.data.copyWith(fontSize: 11, color: style.colors.surface),
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.bars,
    required this.current,
    required this.target,
    required this.semanticLabel,
  });

  final List<ChartBar> bars;
  final int? current;
  final double? target;
  final String semanticLabel;

  static const height = 130.0;
  static const radius = BorderRadius.all(Radius.circular(4));

  /// The highest of the values and the goal reaches this share of the bars'
  /// height.
  static const peak = 0.95;

  /// A bar with no value yet: a stub of this share.
  static const stub = 0.03;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final valueStyle = style.data.copyWith(fontSize: 10);
    final painter = TextPainter(
      text: TextSpan(text: '0', style: valueStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final labelHeight = painter.height;
    painter.dispose();
    final barArea = height - labelHeight - Gap.xs;
    final target = this.target;
    final top =
        [
          for (final bar in bars) ?bar.value,
          ?target,
        ].fold<double>(0, math.max) /
        peak;
    // Bars grow up from zero: a negative value draws none.
    double share(double value) => top <= 0 ? 0 : math.max(0.0, value) / top;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Gap.sm,
        children: [
          SizedBox(
            height: height,
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: Gap.sm,
                  children: [
                    for (final (i, bar) in bars.indexed)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: Gap.xs,
                          children: bar.value == null
                              ? [
                                  Container(
                                    height: barArea * stub,
                                    decoration: BoxDecoration(
                                      color: colors.surfaceSunken,
                                      borderRadius: radius,
                                    ),
                                  ),
                                ]
                              : [
                                  Text(
                                    bar.valueLabel!,
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.visible,
                                    softWrap: false,
                                    style: valueStyle.copyWith(
                                      color: i == current
                                          ? colors.ink
                                          : colors.inkMuted,
                                    ),
                                  ),
                                  Container(
                                    height: barArea * share(bar.value!),
                                    decoration: BoxDecoration(
                                      color: i == current
                                          ? colors.accent
                                          : colors.accent.withValues(
                                              alpha: 0.55,
                                            ),
                                      borderRadius: radius,
                                    ),
                                  ),
                                ],
                        ),
                      ),
                  ],
                ),
                if (target != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: barArea * share(target) - 0.75,
                    height: 1.5,
                    child: CustomPaint(painter: _GoalPainter(colors.success)),
                  ),
              ],
            ),
          ),
          Row(
            spacing: Gap.sm,
            children: [
              for (final (i, bar) in bars.indexed)
                Expanded(
                  child: Text(
                    bar.label,
                    textAlign: TextAlign.center,
                    style: text.labelSmall!.copyWith(
                      color: i == current ? colors.ink : colors.inkMuted,
                      fontWeight: i == current
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalPainter extends CustomPainter {
  const _GoalPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas.drawPath(
      dashed(
        Path()
          ..moveTo(0, y)
          ..lineTo(size.width, y),
        4,
        4,
      ),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.height,
    );
  }

  @override
  bool shouldRepaint(_GoalPainter old) => old.color != color;
}
