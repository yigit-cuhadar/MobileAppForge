import 'package:material_ui/material_ui.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'all_forms.dart';
import 'grid_addon.dart';
import 'main.directories.g.dart';

void main() => runApp(const ForgeWidgetbook());

/// The forge_ui components in every form and state of their MobileAppForge
/// Studio cards, with Forge's own preset in both brightnesses.
@widgetbook.App()
class ForgeWidgetbook extends StatelessWidget {
  const ForgeWidgetbook({super.key});

  @override
  Widget build(BuildContext context) => Widgetbook(
    directories: withAllForms(directories),
    // Widgetbook's material builder and theme addon still use the
    // deprecated package:flutter/material.dart types; these use material_ui.
    appBuilder: (context, child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(child: child),
    ),
    addons: [
      ThemeAddon<ThemeData>(
        themeBuilder: (context, theme, child) => Theme(
          data: theme,
          child: ColoredBox(
            color: theme.scaffoldBackgroundColor,
            child: DefaultTextStyle(
              style: theme.textTheme.bodyMedium!,
              child: child,
            ),
          ),
        ),
        themes: [
          WidgetbookTheme(
            name: '${ForgePreset.slate.name} · Light',
            data: ForgeTheme.light(),
          ),
          WidgetbookTheme(
            name: '${ForgePreset.slate.name} · Dark',
            data: ForgeTheme.dark(),
          ),
        ],
      ),
      ViewportAddon([
        Viewports.none,
        IosViewports.iPhone13,
        IosViewports.iPhoneSE,
        AndroidViewports.samsungGalaxyS20,
      ]),
      TextScaleAddon(min: 1, max: 2, divisions: 4),
      SpacingGridAddon(),
    ],
  );
}
