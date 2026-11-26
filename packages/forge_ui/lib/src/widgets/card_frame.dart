import 'package:material_ui/material_ui.dart';

import '../theme/forge_style.dart';

/// The flat Forge card around [child]: surface, radius-lg and the preset's
/// card border in line, clipped so tinted rows and splashes stay inside.
/// A [tint] mixes that colour into the surface and the border.
class CardFrame extends StatelessWidget {
  const CardFrame({super.key, this.tint, required this.child});

  final Color? tint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final tint = this.tint;
    return Material(
      color: tint == null
          ? colors.surface
          : Color.lerp(colors.surface, tint, 0.12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(style.radii.lg),
        side: style.cardBorder == 0
            ? BorderSide.none
            : BorderSide(
                color: tint == null
                    ? colors.line
                    : Color.lerp(colors.surface, tint, 0.3)!,
                width: style.cardBorder,
              ),
      ),
      child: child,
    );
  }
}
