import 'package:flutter/material.dart';

import 'spacing.dart';

abstract final class ForgeTheme {
  static ThemeData light({Color seed = Colors.indigo}) =>
      _build(seed, Brightness.light);

  static ThemeData dark({Color seed = Colors.indigo}) =>
      _build(seed, Brightness.dark);

  static ThemeData _build(Color seed, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: const CardThemeData(margin: EdgeInsets.all(Gap.sm)),
    );
  }
}
