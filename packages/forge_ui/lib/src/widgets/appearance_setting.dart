import 'package:material_ui/material_ui.dart';

import '../spacing.dart';
import '../theme/forge_theme.dart';
import 'forge_segmented_control.dart';

/// The user's only look setting: Light / Dark / System as a segmented
/// control, as one row of a settings card whose group title names it; the
/// [label] is read out, not drawn. The colour preset is the app's own and
/// has no picker.
class AppearanceSetting extends StatelessWidget {
  const AppearanceSetting({
    super.key,
    required this.label,
    required this.lightLabel,
    required this.darkLabel,
    required this.systemLabel,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String lightLabel;
  final String darkLabel;
  final String systemLabel;
  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  // The control's tap band, taken out of the spacing around it so the
  // drawn track sits gap-md from the card's edges.
  static const double _band =
      (ForgeTheme.tapMin - ForgeSegmentedControl.height) / 2;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: Gap.md,
      vertical: Gap.md - _band,
    ),
    child: Semantics(
      label: label,
      container: true,
      child: ForgeSegmentedControl<ThemeMode>(
        segments: [
          ForgeSegment(value: ThemeMode.light, label: lightLabel),
          ForgeSegment(value: ThemeMode.dark, label: darkLabel),
          ForgeSegment(value: ThemeMode.system, label: systemLabel),
        ],
        selected: value,
        onChanged: onChanged,
      ),
    ),
  );
}
