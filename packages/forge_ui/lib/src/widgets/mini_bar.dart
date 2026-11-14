import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';

/// A 56px accent-soft strip right above the navigation bar while something
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
        child: Container(
          height: height,
          color: style.colors.accentSoft,
          padding: const EdgeInsets.symmetric(horizontal: Gap.md),
          child: Row(
            spacing: Gap.md,
            children: [
              ForgeIcon(icon, size: 20, color: ink),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge!
                          .copyWith(color: ink),
                    ),
                    Text(detail, style: style.data.copyWith(color: ink)),
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
