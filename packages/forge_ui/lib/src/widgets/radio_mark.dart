import 'package:flutter/widgets.dart';

import '../theme/forge_style.dart';

/// The 20px radio of a choice: a line-strong ring, accent with an accent
/// dot when [selected].
class RadioMark extends StatelessWidget {
  const RadioMark({super.key, required this.selected});

  final bool selected;

  static const double size = 20;
  static const double dot = 10;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(style.radii.sm),
        border: Border.all(
          color: selected ? colors.accent : colors.lineStrong,
          width: 2,
        ),
      ),
      child: selected
          ? Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.accent,
              ),
            )
          : null,
    );
  }
}
