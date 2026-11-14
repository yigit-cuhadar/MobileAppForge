import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';

/// One option of a [ForgeSegmentedControl]. A [locked] option shows a small
/// lock before its label in the normal colours.
class ForgeSegment<T> {
  const ForgeSegment({
    required this.value,
    required this.label,
    this.locked = false,
  });

  final T value;
  final String label;
  final bool locked;
}

/// A 36px sunken track of equal segments; the chosen one is a surface
/// tablet. Tapping an option calls [onChanged], or [onLocked] for a locked
/// one (it opens the paywall instead of switching). The track takes taps
/// across a 44px band.
class ForgeSegmentedControl<T> extends StatelessWidget {
  const ForgeSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.onLocked,
  });

  final List<ForgeSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Required when a segment is locked.
  final ValueChanged<T>? onLocked;

  static const double height = 36;
  static const double _inset = 3;
  static const double _gap = 2;

  void _tap(ForgeSegment<T> segment) =>
      segment.locked ? onLocked!(segment.value) : onChanged(segment.value);

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final p = style.colors;
    final label = Theme.of(context).textTheme.bodySmall!;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        // The band above and below the track picks the segment under x;
        // right to left, the first segment sits on the right.
        onTapUp: (details) {
          final fromLeft =
              (details.localPosition.dx /
                      constraints.maxWidth *
                      segments.length)
                  .floor()
                  .clamp(0, segments.length - 1);
          _tap(segments[rtl ? segments.length - 1 - fromLeft : fromLeft]);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: (ForgeTheme.tapMin - height) / 2,
          ),
          child: Container(
            height: height,
            padding: const EdgeInsets.all(_inset),
            decoration: BoxDecoration(
              color: p.surfaceSunken,
              borderRadius: BorderRadius.circular(style.radii.md),
            ),
            child: Row(
              spacing: _gap,
              children: [
                for (final segment in segments)
                  Expanded(
                    child: _Segment(
                      segment: segment,
                      chosen: segment.value == selected,
                      style: label,
                      onTap: () => _tap(segment),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.chosen,
    required this.style,
    required this.onTap,
  });

  final ForgeSegment<T> segment;
  final bool chosen;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final forge = ForgeStyle.of(context);
    final p = forge.colors;
    final ink = chosen ? p.ink : p.inkMuted;
    return Semantics(
      container: true,
      button: true,
      selected: chosen,
      inMutuallyExclusiveGroup: true,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: chosen ? p.surface : null,
          borderRadius: BorderRadius.circular(forge.radii.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: Gap.xs,
          children: [
            if (segment.locked)
              ForgeIcon(ForgeIcons.lock, size: 12, color: ink),
            Flexible(
              child: Text(
                segment.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.copyWith(
                  color: ink,
                  fontWeight: chosen ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
