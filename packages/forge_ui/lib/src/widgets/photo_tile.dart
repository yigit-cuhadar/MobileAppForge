import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import 'busy_ring.dart';
import 'chart_paint.dart';
import 'forge_button.dart';
import 'progress.dart';
import 'skeleton.dart';

enum _State { photo, empty, loading, uploading, failed, offline }

/// A 3:4 photo tile with radius-md corners. A view [label] sits bottom left
/// on a dark translucent tag.
class PhotoTile extends StatelessWidget {
  /// The [image], cropped to fill; a tap opens it. Screen readers name it
  /// by [semanticLabel] ("Front photo, 12 May").
  const PhotoTile({
    super.key,
    required ImageProvider this.image,
    required String this.semanticLabel,
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
       semanticLabel = null,
       image = null,
       progress = null,
       onRetry = null,
       retryLabel = null;

  /// The photo is loading: a shimmering tile that keeps its view [label].
  const PhotoTile.loading({super.key, this.label})
    : _state = _State.loading,
      semanticLabel = null,
      image = null,
      onTap = null,
      message = null,
      progress = null,
      onRetry = null,
      retryLabel = null;

  /// Sending: a spinner and a thin bar at [progress], from 0 to 1.
  const PhotoTile.uploading({super.key, required double this.progress})
    : _state = _State.uploading,
      semanticLabel = null,
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
    required String this.retryLabel,
  }) : _state = _State.failed,
       semanticLabel = null,
       image = null,
       label = null,
       onTap = null,
       progress = null;

  /// Offline: a muted [message] ("Waiting for connection").
  const PhotoTile.offline({super.key, required String this.message})
    : _state = _State.offline,
      semanticLabel = null,
      image = null,
      label = null,
      onTap = null,
      progress = null,
      onRetry = null,
      retryLabel = null;

  final ImageProvider? image;
  final String? semanticLabel;
  final String? label;
  final VoidCallback? onTap;
  final String? message;
  final double? progress;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final _State _state;

  static const double aspectRatio = 3 / 4;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(style.radii.md);
    final small = text.labelMedium!.copyWith(fontWeight: FontWeight.w400);

    final Widget content = switch (_state) {
      _State.photo => ExcludeSemantics(
        child: Image(image: image!, fit: BoxFit.cover),
      ),
      _State.empty => CustomPaint(
        foregroundPainter: DashedOutlinePainter(
          color: colors.lineStrong,
          width: 1.5,
          radius: style.radii.md,
          dash: 4.5,
          gap: 3,
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
      _State.loading => LayoutBuilder(
        builder: (context, constraints) => SkeletonBar(
          widthFactor: 1,
          height: constraints.maxHeight,
          radius: style.radii.md,
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
              child: Progress.track(value: progress!, thin: true),
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
      label: semanticLabel,
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
