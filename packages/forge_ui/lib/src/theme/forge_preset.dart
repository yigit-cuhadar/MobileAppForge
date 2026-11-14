import 'dart:ui';

import 'forge_palette.dart';

/// Corner radii of a preset. Buttons and text fields always take [button].
class ForgeRadii {
  const ForgeRadii({required this.sm, required this.md, required this.lg});

  /// Small tiles and the date box.
  final double sm;

  /// Segmented track, choice rows, menus.
  final double md;

  /// Cards and sheets.
  final double lg;

  static const double button = 8;
}

/// One look of an app: colours for both brightnesses, the two families and
/// the radii. An app ships one preset; [ForgeTheme] turns it into ThemeData.
class ForgePreset {
  const ForgePreset({
    required this.name,
    required this.light,
    required this.dark,
    required this.sans,
    required this.mono,
    required this.radii,
  });

  final String name;
  final ForgePalette light;
  final ForgePalette dark;

  /// Font family for text; a family declared by a package is named
  /// `packages/<package>/<family>`.
  final String sans;

  /// Font family for numbers: dates, counts, weights, timers.
  final String mono;
  final ForgeRadii radii;

  /// Forge's default: slate #222B38 on near-black #101213.
  static const slate = ForgePreset(
    name: 'Slate',
    sans: 'packages/forge_ui/Geist',
    mono: 'packages/forge_ui/GeistMono',
    radii: ForgeRadii(sm: 10, md: 12, lg: 16),
    light: ForgePalette(
      ground: Color(0xFFF1F3F6),
      surface: Color(0xFFFFFFFF),
      surfaceBar: Color(0xFFFFFFFF),
      surfaceSunken: Color(0xFFE7EAEF),
      line: Color(0xFFDCE0E7),
      lineStrong: Color(0xFF8B94A3),
      ink: Color(0xFF101213),
      inkMuted: Color(0xFF586273),
      inkSubtle: Color(0xFF6E7787),
      accent: Color(0xFF222B38),
      onAccent: Color(0xFFFFFFFF),
      accentSoft: Color(0xFFE3E7EE),
      onAccentSoft: Color(0xFF222B38),
      featured: Color(0xFF222B38),
      onFeatured: Color(0xFFEEF1F5),
      featuredBorder: Color(0xFF222B38),
      featuredAction: Color(0xFFFFFFFF),
      onFeaturedAction: Color(0xFF101213),
      success: Color(0xFF3F7D62),
      info: Color(0xFF2F6E73),
      danger: Color(0xFFA6473C),
    ),
    dark: ForgePalette(
      ground: Color(0xFF101213),
      surface: Color(0xFF222B38),
      surfaceBar: Color(0xFF171B22),
      surfaceSunken: Color(0xFF2E3848),
      line: Color(0xFF333E50),
      lineStrong: Color(0xFF6B7689),
      ink: Color(0xFFEEF1F5),
      inkMuted: Color(0xFFA6AFBD),
      inkSubtle: Color(0xFF8F99A8),
      accent: Color(0xFFEEF1F5),
      onAccent: Color(0xFF101213),
      accentSoft: Color(0xFF34405A),
      onAccentSoft: Color(0xFFEEF1F5),
      featured: Color(0xFF222B38),
      onFeatured: Color(0xFFEEF1F5),
      featuredBorder: Color(0xFFEEF1F5),
      featuredAction: Color(0xFFEEF1F5),
      onFeaturedAction: Color(0xFF101213),
      success: Color(0xFF79B597),
      info: Color(0xFF7FB8BC),
      danger: Color(0xFFE0907F),
    ),
  );
}
