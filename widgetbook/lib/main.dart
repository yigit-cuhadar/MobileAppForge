import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'grid_addon.dart';
import 'main.directories.g.dart';

void main() => runApp(const ForgeWidgetbook());

/// The forge_ui components in every form and state of their MobileAppForge
/// Studio cards, with Forge's own preset in both brightnesses.
@widgetbook.App()
class ForgeWidgetbook extends StatelessWidget {
  const ForgeWidgetbook({super.key});

  @override
  Widget build(BuildContext context) => Widgetbook.material(
    directories: directories,
    addons: [
      MaterialThemeAddon(
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
