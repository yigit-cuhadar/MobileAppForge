import 'package:material_ui/material_ui.dart';

import '../theme/forge_style.dart';

/// The small bar that shows a sheet, or a page risen from the bottom, can
/// be dragged down: 36 × 4, rounded, the strong line colour at 60 %,
/// centred. Only a mark; the drag is its container's.
class ForgeGrabber extends StatelessWidget {
  const ForgeGrabber({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: ForgeStyle.of(context).colors.lineStrong.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}
