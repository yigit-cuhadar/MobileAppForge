import 'package:flutter/material.dart';

import '../theme/forge_style.dart';

/// The flat Forge card around [child]: surface, radius-lg and the preset's
/// card border in line, clipped so tinted rows and splashes stay inside.
class CardFrame extends StatelessWidget {
  const CardFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    return Material(
      color: style.colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(style.radii.lg),
        side: style.cardBorder == 0
            ? BorderSide.none
            : BorderSide(color: style.colors.line, width: style.cardBorder),
      ),
      child: child,
    );
  }
}
