import 'package:flutter/material.dart';

import '../spacing.dart';
import 'forge_palette.dart';
import 'forge_preset.dart';
import 'forge_style.dart';

/// Turns a [ForgePreset] into Material 3 ThemeData: the colour scheme, the
/// type scale and the component themes. Screens built from roles change
/// look with the preset without being edited.
abstract final class ForgeTheme {
  static ThemeData light([ForgePreset preset = ForgePreset.slate]) =>
      _build(preset, preset.light, Brightness.light);

  static ThemeData dark([ForgePreset preset = ForgePreset.slate]) =>
      _build(preset, preset.dark, Brightness.dark);

  /// Smallest touch target.
  static const double tapMin = 44;

  /// Every button; the full-width primary action at a page's bottom is
  /// [buttonHeightLg].
  static const double buttonHeight = 40;
  static const double buttonHeightLg = 48;

  static ThemeData _build(
    ForgePreset preset,
    ForgePalette p,
    Brightness brightness,
  ) {
    final light = brightness == Brightness.light;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.accent,
      onPrimary: p.onAccent,
      primaryContainer: p.accentSoft,
      onPrimaryContainer: p.onAccentSoft,
      secondary: p.success,
      onSecondary: p.onAccent,
      secondaryContainer: p.surfaceSunken,
      onSecondaryContainer: p.ink,
      tertiary: p.info,
      onTertiary: p.onAccent,
      error: p.danger,
      onError: p.onAccent,
      surface: p.ground,
      onSurface: p.ink,
      onSurfaceVariant: p.inkMuted,
      surfaceContainerLowest: p.surface,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.surface,
      surfaceContainerHigh: p.surface,
      surfaceContainerHighest: p.surfaceSunken,
      outline: p.lineStrong,
      outlineVariant: p.line,
      inverseSurface: p.ink,
      onInverseSurface: p.ground,
      inversePrimary: p.accentSoft,
      shadow: const Color(0xFF101213),
      scrim: const Color(0x61101213),
      surfaceTint: Colors.transparent,
    );
    final text = _textTheme(preset, p);
    final radii = preset.radii;
    final cardBorder = light || preset.outlinedInDark ? 1.0 : 0.0;
    const buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(ForgeRadii.button)),
    );
    const buttonSize = Size(64, buttonHeight);
    const buttonPadding = EdgeInsets.symmetric(horizontal: Gap.md);
    WidgetStateProperty<Color?> disabled(Color color) =>
        WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled) ? color : null,
        );
    OutlineInputBorder field(Color color, double width) => OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(ForgeRadii.button)),
      borderSide: BorderSide(color: color, width: width),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: preset.sans,
      textTheme: text,
      scaffoldBackgroundColor: p.ground,
      canvasColor: p.ground,
      dividerColor: p.line,
      splashFactory: InkSparkle.splashFactory,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [
        ForgeStyle(
          colors: p,
          radii: radii,
          cardBorder: cardBorder,
          data: _mono(preset, p, 12, 16, FontWeight.w400),
          dataLg: _mono(preset, p, 22, 26, FontWeight.w400),
          buttonLg: _sans(preset, p, 15, 20, FontWeight.w600),
        ),
      ],
      iconTheme: IconThemeData(color: p.ink, size: 24),
      appBarTheme: AppBarTheme(
        backgroundColor: p.ground,
        foregroundColor: p.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 52,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: p.ink, size: 24),
        actionsIconTheme: IconThemeData(color: p.ink, size: 24),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.all(Gap.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.lg),
          side: cardBorder == 0
              ? BorderSide.none
              : BorderSide(color: p.line, width: cardBorder),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(buttonSize),
          padding: const WidgetStatePropertyAll(buttonPadding),
          shape: const WidgetStatePropertyAll(buttonShape),
          textStyle: WidgetStatePropertyAll(text.labelLarge),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: disabled(p.surfaceSunken),
          foregroundColor: disabled(p.lineStrong),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
          foregroundColor: p.ink,
          disabledForegroundColor: p.lineStrong,
          side: BorderSide(color: p.lineStrong),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: Gap.sm),
          shape: buttonShape,
          textStyle: text.labelLarge,
          foregroundColor: p.accent,
          disabledForegroundColor: p.lineStrong,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: buttonSize,
          padding: buttonPadding,
          shape: buttonShape,
          textStyle: text.labelLarge,
          elevation: 0,
          backgroundColor: p.surfaceSunken,
          foregroundColor: p.ink,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.ink,
          minimumSize: const Size.square(tapMin),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Gap.md,
          vertical: 12,
        ),
        hintStyle: text.bodyMedium!.copyWith(color: p.inkSubtle),
        labelStyle: text.bodyMedium!.copyWith(color: p.inkMuted),
        floatingLabelStyle: text.bodySmall!.copyWith(color: p.inkMuted),
        helperStyle: text.bodySmall!.copyWith(color: p.inkMuted),
        errorStyle: text.bodySmall!.copyWith(color: p.danger),
        prefixIconColor: p.inkMuted,
        suffixIconColor: p.inkMuted,
        border: field(p.lineStrong, 1),
        enabledBorder: field(p.lineStrong, 1),
        disabledBorder: field(p.line, 1),
        focusedBorder: field(p.accent, 2),
        errorBorder: field(p.danger, 2),
        focusedErrorBorder: field(p.danger, 2),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.accentSoft,
        selectionHandleColor: p.accent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.accentSoft,
        disabledColor: p.surfaceSunken,
        checkmarkColor: p.onAccentSoft,
        showCheckmark: false,
        labelStyle: _sans(preset, p, 13, 18, FontWeight.w500),
        secondaryLabelStyle: _sans(
          preset,
          p,
          13,
          18,
          FontWeight.w500,
        ).copyWith(color: p.onAccentSoft),
        padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 6),
        labelPadding: const EdgeInsets.symmetric(horizontal: Gap.xs),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(ForgeRadii.button)),
        ),
        side: WidgetStateBorderSide.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BorderSide(color: p.accent, width: 1.5)
              : BorderSide(color: p.lineStrong),
        ),
        iconTheme: IconThemeData(color: p.inkMuted, size: 18),
        elevation: 0,
        pressElevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: p.surfaceBar,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? _sans(
                  preset,
                  p,
                  11,
                  14,
                  FontWeight.w700,
                ).copyWith(color: p.accent)
              : _sans(
                  preset,
                  p,
                  11,
                  14,
                  FontWeight.w500,
                ).copyWith(color: p.inkSubtle),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? p.accent
                : p.inkSubtle,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.ink,
        unselectedLabelColor: p.inkMuted,
        labelStyle: _sans(preset, p, 14, 20, FontWeight.w600),
        unselectedLabelStyle: _sans(preset, p, 14, 20, FontWeight.w500),
        indicatorColor: p.accent,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: p.line,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        modalBarrierColor: scheme.scrim,
        dragHandleColor: p.lineStrong.withValues(alpha: 0.6),
        dragHandleSize: const Size(36, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radii.lg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        barrierColor: scheme.scrim,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.lg),
        ),
        titleTextStyle: _sans(
          preset,
          p,
          18,
          24,
          FontWeight.w600,
        ).copyWith(letterSpacing: -0.18),
        contentTextStyle: text.bodyMedium!.copyWith(color: p.inkMuted),
        actionsPadding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.lg),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.ink,
        contentTextStyle: _sans(
          preset,
          p,
          14,
          19,
          FontWeight.w400,
        ).copyWith(color: p.ground),
        actionTextColor: p.ground,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(ForgeRadii.button)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: scheme.shadow.withValues(alpha: 0.3),
        textStyle: text.bodyLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.md),
          side: BorderSide(color: p.line),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(p.surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radii.md),
              side: BorderSide(color: p.line),
            ),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.onAccent : p.lineStrong,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.accent : p.surface,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.accent : p.lineStrong,
        ),
        trackOutlineWidth: const WidgetStatePropertyAll(2),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.accent : p.surface,
        ),
        checkColor: WidgetStatePropertyAll(p.onAccent),
        side: BorderSide(color: p.lineStrong, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.sm / 2),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? p.accent : p.lineStrong,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: p.accent,
        inactiveTrackColor: p.surfaceSunken,
        thumbColor: p.accent,
        overlayColor: p.accent.withValues(alpha: 0.08),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accent,
        linearTrackColor: p.surfaceSunken,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 6,
        borderRadius: const BorderRadius.all(Radius.circular(3)),
      ),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: p.inkMuted,
        textColor: p.ink,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: _sans(
          preset,
          p,
          12,
          16,
          FontWeight.w400,
        ).copyWith(color: p.inkMuted),
        leadingAndTrailingTextStyle: text.bodyMedium!.copyWith(
          color: p.inkMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: Gap.md),
        minVerticalPadding: Gap.sm,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            _sans(preset, p, 13, 18, FontWeight.w500),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? p.surface
                : p.surfaceSunken,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? p.ink : p.inkMuted,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: p.surfaceSunken)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radii.md),
            ),
          ),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: p.surface,
        headerForegroundColor: p.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.lg),
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.lg),
        ),
      ),
    );
  }

  /// The studio's type scale mapped onto Material's roles.
  static TextTheme _textTheme(ForgePreset preset, ForgePalette p) => TextTheme(
    displayLarge: _sans(preset, p, 57, 64, FontWeight.w400),
    displayMedium: _sans(preset, p, 45, 52, FontWeight.w400),
    displaySmall: _sans(preset, p, 36, 44, FontWeight.w400),
    headlineLarge: _sans(preset, p, 32, 40, FontWeight.w600),
    // hero: the one featured name on a screen
    headlineMedium: _sans(
      preset,
      p,
      30,
      34,
      FontWeight.w600,
    ).copyWith(letterSpacing: -0.9),
    // stat: a big figure
    headlineSmall: _mono(
      preset,
      p,
      28,
      32,
      FontWeight.w600,
    ).copyWith(letterSpacing: -0.84),
    // page-title: the app bar title
    titleLarge: _sans(preset, p, 17, 22, FontWeight.w600),
    // title: card and section titles
    titleMedium: _sans(preset, p, 15, 20, FontWeight.w600),
    // section headings above a group
    titleSmall: _sans(
      preset,
      p,
      13,
      18,
      FontWeight.w600,
    ).copyWith(color: p.inkMuted),
    // list rows and sheet options
    bodyLarge: _sans(preset, p, 15, 20, FontWeight.w400),
    // body: running text
    bodyMedium: _sans(preset, p, 14, 20, FontWeight.w400),
    // body-sm: secondary lines
    bodySmall: _sans(
      preset,
      p,
      13,
      18,
      FontWeight.w400,
    ).copyWith(color: p.inkMuted),
    // button
    labelLarge: _sans(preset, p, 14, 20, FontWeight.w600),
    // label: weekday letters, chip hints
    labelMedium: _sans(preset, p, 12, 16, FontWeight.w500),
    // label-sm: tab labels
    labelSmall: _sans(preset, p, 11, 14, FontWeight.w500),
  );

  static TextStyle _sans(
    ForgePreset preset,
    ForgePalette p,
    double size,
    double lineHeight,
    FontWeight weight,
  ) => TextStyle(
    fontFamily: preset.sans,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    color: p.ink,
    letterSpacing: 0,
  );

  static TextStyle _mono(
    ForgePreset preset,
    ForgePalette p,
    double size,
    double lineHeight,
    FontWeight weight,
  ) => _sans(preset, p, size, lineHeight, weight).copyWith(
    fontFamily: preset.mono,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
