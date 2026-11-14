import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_palette.dart';
import '../theme/forge_preset.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';
import 'busy_ring.dart';
import 'chart_paint.dart';
import 'pressable.dart';

enum ForgeButtonVariant {
  /// The one main action of a screen, in accent.
  primary,

  /// A quieter action on a sunken fill.
  secondary,

  /// An accent label with no fill.
  text,

  /// A destructive action: a danger outline.
  danger,

  /// Retry and other recover actions: an ink label in a line-strong outline.
  outline,

  /// A button on the featured block.
  featured,
}

enum ForgeButtonSize {
  /// 40px, 14px label.
  regular,

  /// 32px, 13px label, for a button inside a row.
  small,

  /// 48px, 15px label, full width: the one primary action at a page's
  /// bottom.
  large,
}

/// A button in one of the studio's forms. It takes taps across a 44px band,
/// and while [loading] it keeps its colours, shows a spinner before the
/// label and ignores taps. A [locked] button shows a lock before the label
/// and stays tappable: [onPressed] then opens the paywall. A [leadingIcon]
/// sits before the label where neither of those does.
class ForgeButton extends StatelessWidget {
  const ForgeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ForgeButtonVariant.primary,
    this.size = ForgeButtonSize.regular,
    this.loading = false,
    this.locked = false,
    this.leadingIcon,
    this.trailingIcon,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final ForgeButtonVariant variant;
  final ForgeButtonSize size;
  final bool loading;
  final bool locked;
  final ForgeIconData? leadingIcon;
  final ForgeIconData? trailingIcon;

  /// The drawn height of the small form.
  static const double smallHeight = 32;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final p = style.colors;
    final text = Theme.of(context).textTheme;
    final enabled = onPressed != null;
    final (height, padding, labelStyle, iconSize) = switch (size) {
      ForgeButtonSize.regular => (
        ForgeTheme.buttonHeight,
        Gap.md,
        text.labelLarge!,
        16.0,
      ),
      ForgeButtonSize.small => (
        smallHeight,
        Gap.sm,
        text.labelLarge!.copyWith(fontSize: 13),
        14.0,
      ),
      ForgeButtonSize.large => (
        ForgeTheme.buttonHeightLg,
        Gap.md,
        style.buttonLg,
        20.0,
      ),
    };

    final button = Pressable(
      onTap: enabled && !loading ? onPressed : null,
      height: height,
      builder: (context, pressed) {
        final look = _Look.of(variant, p, enabled: enabled, pressed: pressed);
        return Opacity(
          opacity: look.opacity,
          child: Container(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: padding),
            decoration: BoxDecoration(
              color: look.fill,
              borderRadius: const BorderRadius.all(
                Radius.circular(ForgeRadii.button),
              ),
              border: look.border == null
                  ? null
                  : Border.all(color: look.border!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading) ...[
                  BusyRing(size: 14, stroke: 2, sweep: 0.75, color: look.ink),
                  const SizedBox(width: Gap.sm),
                ] else if (locked) ...[
                  ForgeIcon(ForgeIcons.lock, size: iconSize, color: look.ink),
                  const SizedBox(width: Gap.sm),
                ] else if (leadingIcon case final icon?) ...[
                  ForgeIcon(icon, size: iconSize, color: look.ink),
                  const SizedBox(width: Gap.sm),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle.copyWith(color: look.ink),
                  ),
                ),
                if (trailingIcon case final icon?) ...[
                  const SizedBox(width: Gap.sm),
                  ForgeIcon(icon, size: iconSize, color: look.ink),
                ],
              ],
            ),
          ),
        );
      },
    );

    return Semantics(
      button: true,
      enabled: enabled && !loading,
      child: size == ForgeButtonSize.large
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }
}

class _Look {
  const _Look(this.fill, this.ink, {this.border, this.opacity = 1});

  final Color fill;
  final Color ink;
  final Color? border;
  final double opacity;

  static const _clear = Color(0x00000000);

  static _Look of(
    ForgeButtonVariant variant,
    ForgePalette p, {
    required bool enabled,
    required bool pressed,
  }) => switch (variant) {
    ForgeButtonVariant.primary =>
      enabled
          ? _Look(
              pressed ? Color.lerp(p.accent, p.ink, 0.18)! : p.accent,
              p.onAccent,
            )
          : _Look(p.surfaceSunken, p.lineStrong),
    ForgeButtonVariant.secondary => _Look(
      pressed ? p.line : p.surfaceSunken,
      p.ink,
      opacity: enabled ? 1 : 0.4,
    ),
    ForgeButtonVariant.text => _Look(
      pressed ? p.accentSoft : _clear,
      enabled ? p.accent : p.lineStrong,
    ),
    ForgeButtonVariant.danger =>
      enabled
          ? _Look(
              pressed ? p.danger.withValues(alpha: 0.08) : _clear,
              p.danger,
              border: p.danger,
            )
          : _Look(_clear, p.lineStrong, border: p.line),
    ForgeButtonVariant.outline =>
      enabled
          ? _Look(
              pressed ? Color.lerp(p.surface, p.ink, 0.08)! : p.surface,
              p.ink,
              border: p.lineStrong,
            )
          : _Look(p.surface, p.lineStrong, border: p.line),
    ForgeButtonVariant.featured => _Look(
      pressed
          ? Color.lerp(p.featuredAction, p.featured, 0.18)!
          : p.featuredAction,
      p.onFeaturedAction,
      opacity: enabled ? 1 : 0.4,
    ),
  };
}

/// The dashed full-width "Add …" button at the end of a list.
class ForgeAddButton extends StatelessWidget {
  const ForgeAddButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final p = style.colors;
    return Semantics(
      button: true,
      child: Pressable(
        onTap: onPressed,
        height: ForgeTheme.tapMin,
        builder: (context, pressed) => CustomPaint(
          foregroundPainter: DashedOutlinePainter(
            color: p.lineStrong,
            width: 1,
            radius: style.radii.lg,
            dash: 3,
            gap: 3,
          ),
          child: Container(
            height: ForgeTheme.tapMin,
            width: double.infinity,
            decoration: BoxDecoration(
              color: pressed ? Color.lerp(p.surface, p.ink, 0.08) : p.surface,
              borderRadius: BorderRadius.circular(style.radii.lg),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ForgeIcon(ForgeIcons.add, size: 18, color: p.ink),
                const SizedBox(width: Gap.sm),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge!
                        .copyWith(color: p.ink),
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
