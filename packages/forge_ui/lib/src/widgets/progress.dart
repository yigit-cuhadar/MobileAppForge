import 'dart:math';

import 'package:material_ui/material_ui.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';
import 'runner_line.dart';
import 'skeleton.dart';

/// Progress toward a goal as a thin bar or a ring on surface-sunken, with
/// the [figure] and a [caption]. Reaching the [goal] turns the fill and the
/// caption success. [Progress.track] is the bare bar,
/// [Progress.segmented] the bare bar in parts;
/// [Progress.indeterminate] stands for work of unknown length.
class Progress extends StatelessWidget {
  /// A 6px bar under the figure, the caption at the right.
  const Progress.bar({
    super.key,
    required this.value,
    required double this.goal,
    required String this.figure,
    required String this.caption,
  }) : _form = _Form.bar,
       segments = null,
       thin = false,
       label = null;

  /// A 136px ring with an 8px stroke, the figure and caption inside.
  const Progress.ring({
    super.key,
    required this.value,
    required double this.goal,
    required String this.figure,
    required String this.caption,
  }) : _form = _Form.ring,
       segments = null,
       thin = false,
       label = null;

  /// The ring while its value loads: a shimmering 136px circle.
  const Progress.ringLoading({super.key})
    : _form = _Form.ringLoading,
      segments = null,
      value = 0,
      goal = null,
      figure = null,
      caption = null,
      thin = false,
      label = null;

  /// The bare bar: 6px on surface-sunken, or [thin], 4px on line. Filled in
  /// accent to [value], from 0 to 1; given a [goal], to [value] out of it,
  /// in success once it is reached.
  const Progress.track({
    super.key,
    required this.value,
    this.goal,
    this.thin = false,
  }) : _form = _Form.track,
       segments = null,
       figure = null,
       caption = null,
       label = null;

  /// The bare 6px bar cut into [segments] (a program's weeks), 4px apart,
  /// filled in accent to [value], from 0 to 1 of the whole: the segments
  /// before it full, the one it ends in partly.
  const Progress.segmented({
    super.key,
    required this.value,
    required int this.segments,
  }) : assert(segments > 0),
       _form = _Form.segmented,
       goal = null,
       figure = null,
       caption = null,
       thin = false,
       label = null;

  /// A 3px line, full width, an ink-muted runner crossing its track again
  /// and again: under the app bar while the page saves. Screen readers
  /// hear [label] ("Saving").
  const Progress.indeterminate({super.key, required String this.label})
    : _form = _Form.indeterminate,
      segments = null,
      value = 0,
      goal = null,
      figure = null,
      caption = null,
      thin = false;

  final double value;
  final double? goal;
  final String? figure;
  final String? caption;
  final bool thin;
  final String? label;
  final int? segments;
  final _Form _form;

  static const _barHeight = 6.0;
  static const _thinHeight = 4.0;
  static const _ringSize = 136.0;
  static const _ringStroke = 8.0;

  bool get _reached => goal != null && value >= goal!;

  double get _share => goal! <= 0 ? 1 : (value / goal!).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    if (_form == _Form.ringLoading) {
      return const SkeletonBar(width: _ringSize, height: _ringSize);
    }
    if (_form == _Form.indeterminate) {
      return Semantics(
        label: label,
        child: RunnerLine(color: colors.inkMuted),
      );
    }
    if (segments case final segments?) {
      final filled = value.clamp(0.0, 1.0) * segments;
      return Row(
        spacing: Gap.xs,
        children: [
          for (var i = 0; i < segments; i++)
            Expanded(
              child: _Track(
                share: (filled - i).clamp(0.0, 1.0),
                height: _barHeight,
                track: colors.surfaceSunken,
                fill: colors.accent,
              ),
            ),
        ],
      );
    }
    final fill = _reached ? colors.success : colors.accent;
    if (_form == _Form.track) {
      return _Track(
        share: goal == null ? value.clamp(0.0, 1.0) : _share,
        height: thin ? _thinHeight : _barHeight,
        track: thin ? colors.line : colors.surfaceSunken,
        fill: fill,
      );
    }
    final text = Theme.of(context).textTheme;
    // stat-style, in sans at 22px.
    final figureStyle = text.titleMedium!.copyWith(
      fontSize: 22,
      height: 26 / 22,
      letterSpacing: -0.44,
    );
    if (_form == _Form.ring) {
      return SizedBox.square(
        dimension: _ringSize,
        child: CustomPaint(
          painter: _RingPainter(
            share: _share,
            track: colors.surfaceSunken,
            fill: fill,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 2,
            children: [
              Text(figure!, style: figureStyle),
              Text(
                caption!,
                textAlign: TextAlign.center,
                style: text.labelSmall!.copyWith(
                  fontWeight: FontWeight.w400,
                  color: _reached ? colors.success : colors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Gap.sm,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text(figure!, style: figureStyle)),
            Text(
              caption!,
              style: text.labelMedium!.copyWith(
                fontWeight: _reached ? FontWeight.w600 : FontWeight.w400,
                color: _reached ? colors.success : colors.inkMuted,
              ),
            ),
          ],
        ),
        _Track(
          share: _share,
          height: _barHeight,
          track: colors.surfaceSunken,
          fill: fill,
        ),
      ],
    );
  }
}

enum _Form { bar, ring, ringLoading, track, segmented, indeterminate }

class _Track extends StatelessWidget {
  const _Track({
    required this.share,
    required this.height,
    required this.track,
    required this.fill,
  });

  final double share;
  final double height;
  final Color track;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.all(Radius.circular(height / 2));
    return Container(
      height: height,
      alignment: AlignmentDirectional.centerStart,
      decoration: BoxDecoration(color: track, borderRadius: radius),
      child: FractionallySizedBox(
        widthFactor: share,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(color: fill, borderRadius: radius),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.share,
    required this.track,
    required this.fill,
  });

  final double share;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(Progress._ringStroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = Progress._ringStroke;
    canvas.drawOval(rect, paint..color = track);
    if (share > 0) {
      canvas.drawArc(
        rect,
        -pi / 2,
        share * 2 * pi,
        false,
        paint
          ..color = fill
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.share != share || old.track != track || old.fill != fill;
}
