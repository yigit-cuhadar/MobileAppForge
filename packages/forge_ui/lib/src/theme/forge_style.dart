import 'package:flutter/material.dart';

import 'forge_palette.dart';
import 'forge_preset.dart';

/// What [ThemeData] has no slot for: every colour role, the radii, the card
/// border and the mono text styles. Read it with [ForgeStyle.of].
class ForgeStyle extends ThemeExtension<ForgeStyle> {
  const ForgeStyle({
    required this.colors,
    required this.radii,
    required this.cardBorder,
    required this.data,
    required this.dataLg,
    required this.buttonLg,
  });

  final ForgePalette colors;
  final ForgeRadii radii;

  /// Card outline width in [ForgePalette.line]: 1 in light, 0 in dark,
  /// where surface differs enough from ground.
  final double cardBorder;

  /// Dates, counts and small values: mono 12/16 with tabular figures.
  final TextStyle data;

  /// Large values such as a stepper's weight: mono 22/26.
  final TextStyle dataLg;

  /// The label of the full-width primary action at a page's bottom: 15/20.
  final TextStyle buttonLg;

  /// The featured block's outline width, in [ForgePalette.featuredBorder].
  static const double featuredBorder = 1.5;

  static ForgeStyle of(BuildContext context) =>
      Theme.of(context).extension<ForgeStyle>()!;

  @override
  ForgeStyle copyWith({
    ForgePalette? colors,
    ForgeRadii? radii,
    double? cardBorder,
    TextStyle? data,
    TextStyle? dataLg,
    TextStyle? buttonLg,
  }) => ForgeStyle(
    colors: colors ?? this.colors,
    radii: radii ?? this.radii,
    cardBorder: cardBorder ?? this.cardBorder,
    data: data ?? this.data,
    dataLg: dataLg ?? this.dataLg,
    buttonLg: buttonLg ?? this.buttonLg,
  );

  @override
  ForgeStyle lerp(ForgeStyle? other, double t) {
    if (other == null) return this;
    return ForgeStyle(
      colors: ForgePalette.lerp(colors, other.colors, t),
      radii: t < 0.5 ? radii : other.radii,
      cardBorder: t < 0.5 ? cardBorder : other.cardBorder,
      data: TextStyle.lerp(data, other.data, t)!,
      dataLg: TextStyle.lerp(dataLg, other.dataLg, t)!,
      buttonLg: TextStyle.lerp(buttonLg, other.buttonLg, t)!,
    );
  }
}
