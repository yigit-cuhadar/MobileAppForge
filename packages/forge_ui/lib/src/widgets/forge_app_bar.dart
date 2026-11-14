import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_preset.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';

/// The page's top bar: a centred title on every page, tab roots too. A page
/// that can go back shows back on the left; a full-screen dialog route (a
/// page opened over the flow) shows close instead. Actions sit right.
class ForgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ForgeAppBar({super.key, required this.title, this.actions = const []});

  final String title;

  /// [ForgeAppBarAction]s, left to right.
  final List<Widget> actions;

  static const double height = 52;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final close = route is PageRoute && route.fullscreenDialog;
    final strings = MaterialLocalizations.of(context);
    final leading = route?.impliesAppBarDismissal ?? false
        ? ForgeAppBarAction.icon(
            icon: close
                ? ForgeIcons.close
                : Directionality.of(context) == TextDirection.rtl
                ? ForgeIcons.chevronRight
                : ForgeIcons.chevronLeft,
            label: close
                ? strings.closeButtonTooltip
                : strings.backButtonTooltip,
            onPressed: () => Navigator.maybePop(context),
          )
        : null;
    final ground = ForgeStyle.of(context).colors.ground;
    // Status bar icons in the contrast of the page's ground.
    final overlay =
        ThemeData.estimateBrightnessForColor(ground) == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlay.copyWith(statusBarColor: Colors.transparent),
      child: Material(
        color: ground,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
              child: NavigationToolbar(
                leading: leading,
                middle: Semantics(
                  header: true,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions,
                ),
                middleSpacing: Gap.xs,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An action in a [ForgeAppBar]: a text action in accent, or a 44px icon
/// with an optional accent count while it is in effect (filters on).
class ForgeAppBarAction extends StatelessWidget {
  /// Fades to 40% while [onPressed] is null (a form missing a field).
  const ForgeAppBarAction.text({
    super.key,
    required String this.label,
    required this.onPressed,
  }) : icon = null,
       count = null;

  const ForgeAppBarAction.icon({
    super.key,
    required ForgeIconData this.icon,
    required String this.label,
    required this.onPressed,
    this.count,
  });

  final ForgeIconData? icon;

  /// The text, or the icon's semantic label.
  final String? label;
  final VoidCallback? onPressed;

  /// Shown on the icon while it is non-null.
  final int? count;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final icon = this.icon;
    if (icon == null) {
      return Opacity(
        opacity: onPressed == null ? 0.4 : 1,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(disabledForegroundColor: colors.accent),
          child: Text(label!),
        ),
      );
    }
    final count = this.count;
    return Semantics(
      button: true,
      label: label,
      value: count?.toString(),
      enabled: onPressed != null,
      onTap: onPressed,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onPressed,
        radius: ForgeTheme.tapMin / 2,
        child: SizedBox.square(
          dimension: ForgeTheme.tapMin,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ForgeIcon(icon, size: 22, color: colors.ink),
              if (count != null)
                PositionedDirectional(
                  top: 6,
                  end: 5,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(ForgeRadii.button),
                    ),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: style.data.copyWith(
                        fontSize: 10,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                        color: colors.onAccent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
