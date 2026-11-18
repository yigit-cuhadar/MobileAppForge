import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _row(List<Widget> buttons) => Center(
  child: Row(mainAxisSize: MainAxisSize.min, children: buttons),
);

@widgetbook.UseCase(name: 'Muted', type: ForgeIconButton)
Widget mutedIconButtons(BuildContext context) => _row([
  ForgeIconButton(icon: ForgeIcons.close, label: 'Remove', onPressed: () {}),
  ForgeIconButton(icon: ForgeIcons.help, label: 'Help', onPressed: () {}),
  ForgeIconButton(icon: ForgeIcons.moreHoriz, label: 'More', onPressed: () {}),
]);

@widgetbook.UseCase(name: 'Ink', type: ForgeIconButton)
Widget inkIconButtons(BuildContext context) => _row([
  ForgeIconButton(
    icon: ForgeIcons.chevronLeft,
    label: 'Back',
    onPressed: () {},
    variant: ForgeIconButtonVariant.ink,
  ),
  ForgeIconButton(
    icon: ForgeIcons.playArrow,
    label: 'Start',
    onPressed: () {},
    variant: ForgeIconButtonVariant.ink,
  ),
]);

@widgetbook.UseCase(name: 'On featured', type: ForgeIconButton)
Widget onFeaturedIconButton(BuildContext context) {
  final style = ForgeStyle.of(context);
  return Center(
    child: Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: style.colors.featured,
        borderRadius: BorderRadius.circular(style.radii.lg),
      ),
      child: ForgeIconButton(
        icon: ForgeIcons.moreHoriz,
        label: 'More',
        onPressed: () {},
        variant: ForgeIconButtonVariant.onFeatured,
      ),
    ),
  );
}

@widgetbook.UseCase(name: 'Disabled', type: ForgeIconButton)
Widget disabledIconButton(BuildContext context) => _row(const [
  ForgeIconButton(icon: ForgeIcons.close, label: 'Remove', onPressed: null),
  ForgeIconButton(
    icon: ForgeIcons.playArrow,
    label: 'Start',
    onPressed: null,
    variant: ForgeIconButtonVariant.ink,
  ),
]);
