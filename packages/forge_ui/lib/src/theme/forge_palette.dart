import 'dart:ui';

/// Every colour role of one brightness. Screens use roles, never colours;
/// most reach them through the [ColorScheme] that [ForgeTheme] builds, the
/// rest (bars, the featured block, ink-subtle) through `ForgeStyle.of`.
class ForgePalette {
  const ForgePalette({
    required this.ground,
    required this.surface,
    required this.surfaceBar,
    required this.surfaceSunken,
    required this.line,
    required this.lineStrong,
    required this.ink,
    required this.inkMuted,
    required this.inkSubtle,
    required this.accent,
    required this.onAccent,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.featured,
    required this.onFeatured,
    required this.featuredBorder,
    required this.featuredAction,
    required this.onFeaturedAction,
    required this.success,
    required this.info,
    required this.danger,
  });

  /// Scaffold background behind cards.
  final Color ground;

  /// Cards, sheets, dialogs, the bottom panel.
  final Color surface;

  /// The navigation bar, between ground and surface.
  final Color surfaceBar;

  /// Chips, tracks, skeleton bars, tonal buttons.
  final Color surfaceSunken;

  /// Card borders (light) and dividers; decorative only.
  final Color line;

  /// Control borders, chart ticks; 3:1 on surface.
  final Color lineStrong;

  final Color ink;
  final Color inkMuted;

  /// Unselected navigation items and placeholder hints.
  final Color inkSubtle;

  /// The one primary action per screen and the current thing.
  final Color accent;
  final Color onAccent;

  /// Selected but secondary states.
  final Color accentSoft;
  final Color onAccentSoft;

  /// The featured block, at most one per screen.
  final Color featured;
  final Color onFeatured;

  /// The featured block's 1.5px outline, invisible where it equals the fill.
  final Color featuredBorder;

  /// A button on the featured block.
  final Color featuredAction;
  final Color onFeaturedAction;

  /// Status colours are small marks: dots, bar fills, short text.
  final Color success;
  final Color info;
  final Color danger;

  static ForgePalette lerp(ForgePalette a, ForgePalette b, double t) {
    Color c(Color Function(ForgePalette p) role) =>
        Color.lerp(role(a), role(b), t)!;
    return ForgePalette(
      ground: c((p) => p.ground),
      surface: c((p) => p.surface),
      surfaceBar: c((p) => p.surfaceBar),
      surfaceSunken: c((p) => p.surfaceSunken),
      line: c((p) => p.line),
      lineStrong: c((p) => p.lineStrong),
      ink: c((p) => p.ink),
      inkMuted: c((p) => p.inkMuted),
      inkSubtle: c((p) => p.inkSubtle),
      accent: c((p) => p.accent),
      onAccent: c((p) => p.onAccent),
      accentSoft: c((p) => p.accentSoft),
      onAccentSoft: c((p) => p.onAccentSoft),
      featured: c((p) => p.featured),
      onFeatured: c((p) => p.onFeatured),
      featuredBorder: c((p) => p.featuredBorder),
      featuredAction: c((p) => p.featuredAction),
      onFeaturedAction: c((p) => p.onFeaturedAction),
      success: c((p) => p.success),
      info: c((p) => p.info),
      danger: c((p) => p.danger),
    );
  }
}
