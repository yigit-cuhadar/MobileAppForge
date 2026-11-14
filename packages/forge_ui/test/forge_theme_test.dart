import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forge_ui/forge_ui.dart';

void main() {
  const preset = ForgePreset.slate;

  test('maps the roles onto the colour scheme', () {
    final theme = ForgeTheme.light(preset);
    final p = preset.light;
    expect(theme.colorScheme.primary, p.accent);
    expect(theme.colorScheme.surface, p.ground);
    expect(theme.colorScheme.surfaceContainerLow, p.surface);
    expect(theme.colorScheme.onSurfaceVariant, p.inkMuted);
    expect(theme.colorScheme.error, p.danger);
    expect(theme.scaffoldBackgroundColor, p.ground);
  });

  test('cards are outlined in light and tonal in dark', () {
    final light = ForgeTheme.light(preset);
    final dark = ForgeTheme.dark(preset);
    expect(light.extension<ForgeStyle>()!.cardBorder, 1);
    expect(dark.extension<ForgeStyle>()!.cardBorder, 0);
    final lightShape = light.cardTheme.shape! as RoundedRectangleBorder;
    final darkShape = dark.cardTheme.shape! as RoundedRectangleBorder;
    expect(lightShape.side.color, preset.light.line);
    expect(darkShape.side, BorderSide.none);
    expect(dark.cardTheme.color, preset.dark.surface);
  });

  test('a preset can keep the card line in dark', () {
    final outlined = ForgePreset(
      name: 'Outlined',
      light: ForgePreset.slate.light,
      dark: ForgePreset.slate.dark,
      sans: 'Sans',
      mono: 'Mono',
      radii: const ForgeRadii(sm: 8, md: 10, lg: 12),
      outlinedInDark: true,
    );
    final dark = ForgeTheme.dark(outlined);
    expect(dark.extension<ForgeStyle>()!.cardBorder, 1);
    final shape = dark.cardTheme.shape! as RoundedRectangleBorder;
    expect(shape.side.color, outlined.dark.line);
  });

  test('uses the preset families, with tabular mono figures', () {
    final theme = ForgeTheme.light(preset);
    expect(theme.textTheme.titleLarge!.fontFamily, preset.sans);
    expect(theme.textTheme.titleLarge!.fontSize, 17);
    expect(theme.appBarTheme.centerTitle, isTrue);
    final style = theme.extension<ForgeStyle>()!;
    expect(style.data.fontFamily, preset.mono);
    expect(
      style.data.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
    expect(theme.textTheme.headlineSmall!.fontFamily, preset.mono);
  });

  testWidgets('ForgeStyle.of reads the active brightness', (tester) async {
    late ForgeStyle style;
    await tester.pumpWidget(
      MaterialApp(
        theme: ForgeTheme.light(preset),
        darkTheme: ForgeTheme.dark(preset),
        themeMode: ThemeMode.dark,
        home: Builder(
          builder: (context) {
            style = ForgeStyle.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(style.colors.ground, preset.dark.ground);
  });
}
