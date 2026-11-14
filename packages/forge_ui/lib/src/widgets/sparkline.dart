import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_preset.dart';
import '../theme/forge_style.dart';
import 'card_frame.dart';
import 'chart_paint.dart';
import 'forge_button.dart';
import 'skeleton.dart';

/// A trend in a card: the [title] with a chevron (the card opens its
/// page), the latest [figure] and a [caption], then a 2px accent line over
/// a soft accent-soft area with the first and last value under its ends.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.title,
    required this.onTap,
    required String this.figure,
    required String this.caption,
    required List<double> this.values,
    required String this.startLabel,
    required String this.endLabel,
    required String this.semanticLabel,
  }) : _state = _State.filled,
       message = null,
       onRetry = null,
       retryLabel = null;

  /// One entry or none: the [figure] when there is one, and a dashed box
  /// with a [message] where the line will be.
  const Sparkline.empty({
    super.key,
    required this.title,
    this.figure,
    required String this.message,
  }) : _state = _State.empty,
       onTap = null,
       caption = null,
       values = null,
       startLabel = null,
       endLabel = null,
       semanticLabel = null,
       onRetry = null,
       retryLabel = null;

  /// Shimmering bars for the figure and the line.
  const Sparkline.loading({super.key, required this.title})
    : _state = _State.loading,
      onTap = null,
      figure = null,
      caption = null,
      values = null,
      startLabel = null,
      endLabel = null,
      semanticLabel = null,
      message = null,
      onRetry = null,
      retryLabel = null;

  /// Loading failed: a dash for the figure, the [message] in danger and an
  /// outline Retry.
  const Sparkline.error({
    super.key,
    required this.title,
    required String this.message,
    required VoidCallback this.onRetry,
    required String this.retryLabel,
  }) : _state = _State.error,
       onTap = null,
       figure = null,
       caption = null,
       values = null,
       startLabel = null,
       endLabel = null,
       semanticLabel = null;

  final String title;
  final VoidCallback? onTap;
  final String? figure;
  final String? caption;
  final List<double>? values;

  /// The first and the last value, written under the line's ends.
  final String? startLabel;
  final String? endLabel;

  /// What the line shows, for screen readers.
  final String? semanticLabel;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final _State _state;

  static const double _lineHeight = 64;
  static const double _boxHeight = 48;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final stat = text.titleMedium!.copyWith(
      fontSize: 28,
      height: 32 / 28,
      letterSpacing: -0.84,
    );
    final titleRow = Row(
      spacing: Gap.sm,
      children: [
        Expanded(child: Text(title, style: text.titleMedium)),
        if (_state == _State.filled)
          ForgeIcon(ForgeIcons.chevronRight, size: 18, color: colors.inkMuted),
      ],
    );
    final children = switch (_state) {
      _State.filled => [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(figure!, style: stat),
            Text(caption!, style: text.bodySmall),
          ],
        ),
        Semantics(
          container: true,
          label: semanticLabel,
          child: SizedBox(
            height: _lineHeight,
            child: CustomPaint(
              painter: _SparkPainter(
                values: values!,
                line: colors.accent,
                area: colors.accentSoft,
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: Gap.sm,
          children: [
            Text(
              startLabel!,
              style: style.data.copyWith(fontSize: 11, color: colors.inkMuted),
            ),
            Text(
              endLabel!,
              style: style.data.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
      _State.empty => [
        if (figure != null) Text(figure!, style: stat),
        CustomPaint(
          painter: DashedBorderPainter(
            color: colors.lineStrong,
            width: 1,
            radius: ForgeRadii.button,
          ),
          child: SizedBox(
            height: _boxHeight,
            child: Center(
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: text.labelMedium!.copyWith(
                  color: colors.inkMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ],
      _State.loading => [
        SkeletonBar(widthFactor: 0.4, height: 24, radius: style.radii.md),
        const SkeletonBar(
          widthFactor: 1,
          height: _boxHeight,
          radius: ForgeRadii.button,
        ),
      ],
      _State.error => [
        Text('—', style: stat.copyWith(color: colors.inkSubtle)),
        Row(
          spacing: Gap.sm,
          children: [
            Expanded(
              child: Text(
                message!,
                style: text.bodySmall!.copyWith(color: colors.danger),
              ),
            ),
            ForgeButton(
              label: retryLabel!,
              onPressed: onRetry,
              variant: ForgeButtonVariant.outline,
            ),
          ],
        ),
      ],
    };
    final body = Padding(
      padding: const EdgeInsets.all(Gap.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Gap.sm,
        children: [titleRow, ...children],
      ),
    );
    return CardFrame(
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}

enum _State { filled, empty, loading, error }

class _SparkPainter extends CustomPainter {
  const _SparkPainter({
    required this.values,
    required this.line,
    required this.area,
  });

  final List<double> values;
  final Color line;
  final Color area;

  /// Room at the sides for the round caps.
  static const _side = 4.0;

  /// Room above and below the line.
  static const _end = 11.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final xs = spreadX(values.length, _side, size.width - _side);
    final points = [
      for (final (i, v) in values.indexed)
        Offset(xs[i], scaleY(v, min, max, _end, size.height - _end)),
    ];
    final fill = Path()
      ..addPolygon([
        ...points,
        Offset(points.last.dx, size.height),
        Offset(points.first.dx, size.height),
      ], true);
    canvas.drawPath(fill, Paint()..color = area);
    canvas.drawPath(
      Path()..addPolygon(points, false),
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values != values || old.line != line || old.area != area;
}
