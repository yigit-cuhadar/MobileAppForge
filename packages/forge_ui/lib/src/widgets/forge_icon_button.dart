import 'package:material_ui/material_ui.dart';

import '../icons/forge_icon.dart';
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

/// A bare 20px icon on a 44px tap target with a round ripple. [label] names
/// the action for screen readers. Null [onPressed] fades it to 40%. A
/// [toggled] icon is an outline in the variant's colour while off and filled
/// accent while on (a favourite).
class ForgeIconButton extends StatelessWidget {
  const ForgeIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.variant = ForgeIconButtonVariant.muted,
    this.toggled,
  });

  final ForgeIconData icon;
  final String label;
  final VoidCallback? onPressed;
  final ForgeIconButtonVariant variant;

  /// On or off for an icon that switches something; null for a plain one.
  final bool? toggled;

  static const double iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final on = toggled ?? false;
    final color = on
        ? colors.accent
        : switch (variant) {
            ForgeIconButtonVariant.muted => colors.inkMuted,
            ForgeIconButtonVariant.ink => colors.ink,
            ForgeIconButtonVariant.onFeatured => colors.onFeatured,
          };
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
                child: ForgeIcon(
                  icon,
                  size: iconSize,
                  color: color,
                  filled: on,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
