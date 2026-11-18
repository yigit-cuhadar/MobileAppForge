import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_preset.dart';
import '../theme/forge_style.dart';
import '../theme/forge_theme.dart';
import 'header_layout.dart';

/// The page's top bar: a centred title on every page, tab roots too. A page
/// that can go back shows back on the left; a full-screen dialog route (a
/// page opened over the flow) shows close instead. Actions sit right.
class ForgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ForgeAppBar({
    super.key,
    required String this.title,
    this.actions = const [],
    this.back = true,
  }) : leading = null,
       value = null,
       subtitle = null;

  /// In place of the title, a large mono [value] (a running timer) at the
  /// left with the [subtitle] under it, after the [leading] action (a down
  /// chevron that minimises the page). Actions here are a small Button,
  /// which shows its loading state while its work runs, and ⋯. Larger text
  /// grows the bar: the subtitle wraps, and when the actions no longer fit
  /// beside the value they go under it, at the end.
  const ForgeAppBar.value({
    super.key,
    required Widget this.leading,
    required String this.value,
    required String this.subtitle,
    this.actions = const [],
  }) : title = null,
       back = false;

  final String? title;
  final Widget? leading;
  final String? value;
  final String? subtitle;

  /// [ForgeAppBarAction]s, left to right.
  final List<Widget> actions;

  /// False drops back (and close) on a page the user must not leave that
  /// way, though the route could pop: a step that cannot be undone.
  final bool back;

  static const double height = 52;

  /// The value form's height at normal text, and its least.
  static const double valueHeight = 68;

  /// The value form's preferred size: no cap, so a Scaffold lets it take
  /// the height it lays out at. A widget wrapping the form passes it on.
  static const valuePreferredSize = Size.fromHeight(double.maxFinite);

  @override
  Size get preferredSize =>
      value == null ? const Size.fromHeight(height) : valuePreferredSize;

  @override
  Widget build(BuildContext context) {
    final value = this.value;
    if (value != null) return _frame(context, _valueBar(context, value));
    final route = ModalRoute.of(context);
    final close = route is PageRoute && route.fullscreenDialog;
    final strings = MaterialLocalizations.of(context);
    final leading = back && (route?.impliesAppBarDismissal ?? false)
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
    return _frame(
      context,
      SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
          child: NavigationToolbar(
            leading: leading,
            middle: Semantics(
              header: true,
              child: Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: actions),
            middleSpacing: Gap.xs,
          ),
        ),
      ),
    );
  }

  Widget _valueBar(BuildContext context, String value) {
    final style = ForgeStyle.of(context);
    // Larger text wraps the subtitle instead of cutting it, and moves the
    // actions under the value when they no longer fit beside it.
    final scaled = MediaQuery.textScalerOf(context).scale(1) > 1;
    final valueRow = <Widget>[
      leading!,
      Expanded(
        child: Semantics(
          header: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A timer never breaks; it scales down where it must.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  value,
                  maxLines: 1,
                  style: style.dataLg.copyWith(fontSize: 28, height: 32 / 28),
                ),
              ),
              Text(
                subtitle!,
                maxLines: scaled ? null : 1,
                overflow: scaled ? null : TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  fontWeight: FontWeight.w400,
                  color: style.colors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: valueHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.xs, Gap.md, Gap.xs, Gap.xs),
        // At normal text the cut subtitle leaves the actions beside it.
        child: !scaled || actions.isEmpty
            ? Row(spacing: Gap.xs, children: [...valueRow, ...actions])
            : HeaderLayout(
                gap: Gap.xs,
                children: [
                  Row(spacing: Gap.xs, children: valueRow),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: Gap.xs,
                    children: actions,
                  ),
                ],
              ),
      ),
    );
  }

  /// [bar] on the page's ground, under the status bar.
  Widget _frame(BuildContext context, Widget bar) {
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
        child: SafeArea(bottom: false, child: bar),
      ),
    );
  }
}

/// An action in a [ForgeAppBar]: a text action in accent, or a 44px icon
/// with an optional accent count while it is in effect (filters on). A
/// [toggled] icon is an ink outline while off and filled accent while on
/// (a favourite).
class ForgeAppBarAction extends StatelessWidget {
  /// Fades to 40% while [onPressed] is null (a form missing a field).
  const ForgeAppBarAction.text({
    super.key,
    required String this.label,
    required this.onPressed,
  }) : icon = null,
       count = null,
       toggled = null;

  const ForgeAppBarAction.icon({
    super.key,
    required ForgeIconData this.icon,
    required String this.label,
    required this.onPressed,
    this.count,
    this.toggled,
  });

  final ForgeIconData? icon;

  /// The text, or the icon's semantic label.
  final String? label;
  final VoidCallback? onPressed;

  /// Shown on the icon while it is non-null.
  final int? count;

  /// On or off for an icon that switches something; null for a plain one.
  final bool? toggled;

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
      toggled: toggled,
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
              ForgeIcon(
                icon,
                size: 22,
                color: toggled ?? false ? colors.accent : colors.ink,
                filled: toggled ?? false,
              ),
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
