import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';

/// The top of a profile, plain with no card: an avatar, the [name], one
/// [detail] line the app passes (the account, a count) and a chevron to
/// the account page. A signed-in user has their [initials] on accent;
/// [ProfileHeader.guest] has a person icon and asks to create an account.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required String this.initials,
    required this.name,
    required this.detail,
    required this.onTap,
  });

  const ProfileHeader.guest({
    super.key,
    required this.name,
    required this.detail,
    required this.onTap,
  }) : initials = null;

  final String? initials;
  final String name;
  final String detail;
  final VoidCallback onTap;

  static const double _avatar = 56;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final text = Theme.of(context).textTheme;
    final initials = this.initials;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Row(
          spacing: Gap.md,
          children: [
            Container(
              width: _avatar,
              height: _avatar,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: initials == null ? colors.surfaceSunken : colors.accent,
              ),
              child: initials == null
                  ? ForgeIcon(
                      ForgeIcons.person,
                      size: 26,
                      color: colors.inkMuted,
                    )
                  : Text(
                      initials,
                      style: text.titleLarge!.copyWith(
                        fontSize: 20,
                        height: 1.2,
                        color: colors.onAccent,
                      ),
                    ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge!.copyWith(fontSize: 18),
                  ),
                  Text(detail, style: text.bodySmall),
                ],
              ),
            ),
            ForgeIcon(
              ForgeIcons.chevronRight,
              size: 18,
              color: colors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }
}
