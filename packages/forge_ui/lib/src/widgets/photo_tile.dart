import 'dart:ui';

import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import 'busy_ring.dart';
import 'forge_button.dart';

enum _State { photo, empty, uploading, failed, offline }

/// A 3:4 photo tile with radius-md corners. A view [label] sits bottom left
/// on a dark translucent tag.
class PhotoTile extends StatelessWidget {
  /// The [image], cropped to fill; a tap opens it.
  const PhotoTile({
    super.key,
    required ImageProvider this.image,
    this.label,
    required VoidCallback this.onTap,
  }) : _state = _State.photo,
       message = null,
       progress = null,
       onRetry = null,
       retryLabel = null;

  /// No photo yet: a dashed slot with a camera and [message] ("Add photo");
  /// a tap adds one.
  const PhotoTile.empty({
    super.key,
    required String this.message,
    this.label,
    required VoidCallback this.onTap,
  }) : _state = _State.empty,
       image = null,
       progress = null,
       onRetry = null,
       retryLabel = null;

  /// Sending: a spinner and a thin bar at [progress], from 0 to 1.
  const PhotoTile.uploading({super.key, required double this.progress})
    : _state = _State.uploading,
      image = null,
      label = null,
      onTap = null,
      message = null,
      onRetry = null,
      retryLabel = null;

  /// Sending failed: [message] in danger and an outline Retry.
  const PhotoTile.failed({
    super.key,
    required String this.message,
    required VoidCallback this.onRetry,
    String this.retryLabel = 'Retry',
  }) : _state = _State.failed,
       image = null,
       label = null,
       onTap = null,
       progress = null;

  /// Offline: a muted [message] ("Waiting for connection").
  const PhotoTile.offline({super.key, required String this.message})
    : _state = _State.offline,
      image = null,
      label = null,
      onTap = null,
      progress = null,
      onRetry = null,
      retryLabel = null;

  final ImageProvider? image;
  final String? label;
  final VoidCallback? onTap;
  final String? message;
  final double? progress;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final _State _state;

  static const double aspectRatio = 3 / 4;

  /// The bar's fill while uploading, for finding it in tests.
  static const progressKey = ValueKey('PhotoTile.progress');

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(style.radii.md);
    final small = text.labelMedium!.copyWith(fontWeight: FontWeight.w400);

    final Widget content = switch (_state) {
      _State.photo => Image(image: image!, fit: BoxFit.cover),
      _State.empty => CustomPaint(
        foregroundPainter: _DashedBorder(
          color: colors.lineStrong,
          radius: radius,
        ),
        child: ColoredBox(
          color: colors.surface,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: Gap.sm,
              children: [
                ForgeIcon(
                  ForgeIcons.photoCamera,
                  size: 26,
                  color: colors.inkMuted,
                ),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: small.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      _State.uploading => ColoredBox(
        color: colors.surfaceSunken,
        child: Stack(
          children: [
            Center(
              child: BusyRing(
                size: 16,
                stroke: 2,
                sweep: 0.75,
                color: colors.inkMuted.withValues(alpha: 0.8),
              ),
            ),
            Positioned(
              left: Gap.sm,
              right: Gap.sm,
              bottom: Gap.sm,
              height: 4,
              child: _Bar(
                progress: progress!.clamp(0.0, 1.0),
                track: colors.line,
                fill: colors.accent,
              ),
            ),
          ],
        ),
      ),
      _State.failed => ColoredBox(
        color: colors.surfaceSunken,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: Gap.sm,
            children: [
              ForgeIcon(ForgeIcons.error, size: 22, color: colors.danger),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: small.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.danger,
                ),
              ),
              ForgeButton(
                label: retryLabel!,
                onPressed: onRetry,
                variant: ForgeButtonVariant.outline,
              ),
            ],
          ),
        ),
      ),
      _State.offline => ColoredBox(
        color: colors.surfaceSunken,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: Gap.sm,
            children: [
              ForgeIcon(ForgeIcons.cloudOff, size: 22, color: colors.inkMuted),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: small.copyWith(color: colors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    };

    final tile = AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            content,
            if (label != null)
              Positioned(
                left: Gap.sm,
                bottom: Gap.sm,
                child: PhotoTag(
                  label: label!,
                  style: text.labelSmall!.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
    if (onTap == null) return tile;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: tile,
      ),
    );
  }
}

/// A short white label on a dark translucent tag over a photo, the same in
/// both themes.
class PhotoTag extends StatelessWidget {
  const PhotoTag({super.key, required this.label, required this.style});

  final String label;

  /// The label's text style; its colour is replaced.
  final TextStyle style;

  static const double height = 22;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: style.copyWith(color: Colors.white)),
  );
}

class _Bar extends StatelessWidget {
  const _Bar({required this.progress, required this.track, required this.fill});

  final double progress;
  final Color track;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(2));
    return DecoratedBox(
      decoration: BoxDecoration(color: track, borderRadius: radius),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          key: PhotoTile.progressKey,
          widthFactor: progress,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(color: fill, borderRadius: radius),
          ),
        ),
      ),
    );
  }
}

/// A 1.5px dashed outline along the tile's rounded edge.
class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color, required this.radius});

  final Color color;
  final BorderRadius radius;

  static const _width = 1.5;
  static const _dash = 4.5;
  static const _gap = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..addRRect(radius.toRRect(Offset.zero & size).deflate(_width / 2));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width;
    for (final PathMetric metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) =>
      old.color != color || old.radius != radius;
}
