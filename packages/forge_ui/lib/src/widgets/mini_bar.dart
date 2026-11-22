import 'package:material_ui/material_ui.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';

/// A 56px accent-soft strip (taller at large text) right above the navigation bar while something
/// runs: its [icon], [title], a mono [detail] that counts, and an up
/// chevron. A tap opens what runs.
class MiniBar extends StatelessWidget {
  const MiniBar({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final ForgeIconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final ink = style.colors.onAccentSoft;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // Larger text grows the strip past its height.
        child: Container(
          constraints: const BoxConstraints(minHeight: height),
          color: style.colors.accentSoft,
          padding: const EdgeInsets.symmetric(
            horizontal: Gap.md,
            vertical: Gap.xs,
          ),
          child: Row(
            spacing: Gap.md,
            children: [
              ForgeIcon(icon, size: 20, color: ink),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge!
                          .copyWith(color: ink),
                    ),
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style.data.copyWith(color: ink),
                    ),
                  ],
                ),
              ),
              ForgeIcon(ForgeIcons.expandLess, size: 22, color: ink),
            ],
          ),
        ),
      ),
    );
  }
}
