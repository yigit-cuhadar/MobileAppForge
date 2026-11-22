import 'package:material_ui/material_ui.dart';
import 'package:forge_ui/forge_ui.dart';

/// A placeholder provider mark; forge_auth passes the real ones.
class PlaceholderProviderMark extends StatelessWidget {
  const PlaceholderProviderMark({super.key, required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? colors.surface : null,
        border: filled
            ? null
            : Border.all(color: colors.lineStrong, width: 1.5),
      ),
    );
  }
}
