import 'package:material_ui/material_ui.dart';

import '../icons/forge_icon.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';

enum ForgeIconButtonVariant {
  /// Ink-muted: remove, help, more and other actions beside content.
  muted,

  /// Ink: an action that leads somewhere or starts something (back, play).
  ink,

  /// On-featured, on the featured block or another dark band.
  onFeatured,
}

/// What a [ForgeIconButton] sits on.
enum ForgeIconButtonFill {
  /// Nothing: a bare icon.
  none,

  /// A 36px surface-sunken circle: the one action in a row of bare icons
  /// that should read as a button.
  sunken,

  /// A 40px surface circle with a line border: a control over a picture
  /// or a 3D view.
  surface,
}

/// A 20px icon on a 44px tap target with a round ripple, bare or on a
/// [fill]. [label] names the action for screen readers. Null [onPressed]
/// fades it to 40%. A [toggled] button switches something: bare, its icon
/// is an outline in the variant's colour while off and filled accent while
/// on (a favourite); on a fill, the circle turns accent-soft with an accent
/// border while on. [ForgeIconButton.text] shows a short text in place of
/// the icon.
class ForgeIconButton extends StatelessWidget {
  const ForgeIconButton({
    super.key,
    required ForgeIconData this.icon,
    required this.label,
    required this.onPressed,
    this.variant = ForgeIconButtonVariant.muted,
    this.fill = ForgeIconButtonFill.none,
    this.toggled,
  }) : text = null;

  /// A short [text] on a [fill], such as a speed ("0.5×").
  const ForgeIconButton.text(
    String this.text, {
    super.key,
    required this.label,
    required this.onPressed,
    required this.fill,
    this.variant = ForgeIconButtonVariant.muted,
    this.toggled,
  }) : icon = null;

  final ForgeIconData? icon;
  final String? text;
  final String label;
  final VoidCallback? onPressed;
  final ForgeIconButtonVariant variant;
  final ForgeIconButtonFill fill;

  /// On or off for an icon that switches something; null for a plain one.
  final bool? toggled;

  static const double iconSize = 20;
  static const double sunkenSize = 36;
  static const double surfaceSize = 40;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final on = toggled ?? false;
    final bare = fill == ForgeIconButtonFill.none;
    final color = on
        ? bare
              ? colors.accent
              : colors.onAccentSoft
        : switch (variant) {
            ForgeIconButtonVariant.muted => colors.inkMuted,
            ForgeIconButtonVariant.ink => colors.ink,
            ForgeIconButtonVariant.onFeatured => colors.onFeatured,
          };
    final icon = this.icon;
    Widget glyph = icon != null
        ? ForgeIcon(icon, size: iconSize, color: color, filled: on && bare)
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text!,
              maxLines: 1,
              style: Theme.of(context).textTheme.labelMedium!
                  .copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          );
    if (!bare) {
      final sunken = fill == ForgeIconButtonFill.sunken;
      glyph = Container(
        width: sunken ? sunkenSize : surfaceSize,
        height: sunken ? sunkenSize : surfaceSize,
        padding: const EdgeInsets.all(Gap.xs),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on
              ? colors.accentSoft
              : sunken
              ? colors.surfaceSunken
              : colors.surface,
          border: on
              ? Border.all(color: colors.accent, width: 1.5)
              : sunken
              ? null
              : Border.all(color: colors.line),
        ),
        child: glyph,
      );
    }
    return Semantics(
      container: true,
      button: true,
      enabled: onPressed != null,
      label: label,
      toggled: toggled,
      onTap: onPressed,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          onTap: onPressed,
          radius: ForgeTheme.tapMin / 2,
          highlightShape: BoxShape.circle,
          child: SizedBox.square(
            dimension: ForgeTheme.tapMin,
            child: Center(
              child: Opacity(
                opacity: onPressed == null ? 0.4 : 1,
                child: glyph,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
