import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import 'pressable.dart';

bool _cupertino(BuildContext context) => switch (Theme.of(context).platform) {
  TargetPlatform.iOS || TargetPlatform.macOS => true,
  _ => false,
};

/// An on/off switch in the platform's look: the Material switch (outlined
/// off, filled on, the thumb grows) on Android, the iOS switch (filled
/// track, constant white thumb) on iOS. Null [onChanged] disables it.
class ForgeSwitch extends StatelessWidget {
  const ForgeSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final p = ForgeStyle.of(context).colors;
    final enabled = onChanged != null;
    final ios = _cupertino(context);
    final (width, height) = ios ? (50.0, 30.0) : (52.0, 32.0);
    final Widget track;
    if (ios) {
      track = Opacity(
        opacity: enabled ? 1 : 0.5,
        child: AnimatedContainer(
          duration: kThemeAnimationDuration,
          width: width,
          height: height,
          padding: const EdgeInsets.all(2),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: value ? p.accent : p.surfaceSunken,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: value ? p.accent : p.line),
            ),
          ),
        ),
      );
    } else {
      final on = value && enabled;
      final thumb = value ? 22.0 : 14.0;
      final edge = on ? p.accent : (enabled ? p.lineStrong : p.line);
      track = AnimatedContainer(
        duration: kThemeAnimationDuration,
        width: width,
        height: height,
        padding: EdgeInsets.symmetric(horizontal: value ? Gap.xs : 6),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: on ? p.accent : p.surface,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: edge, width: 2),
        ),
        child: AnimatedContainer(
          duration: kThemeAnimationDuration,
          width: thumb,
          height: thumb,
          decoration: BoxDecoration(
            color: on ? p.onAccent : edge,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    return Semantics(
      toggled: value,
      enabled: enabled,
      child: Pressable(
        onTap: enabled ? () => onChanged!(!value) : null,
        height: height,
        width: width,
        builder: (context, _) => track,
      ),
    );
  }
}

/// A checkbox in the platform's look: square with 6px corners on Android,
/// round on iOS; 22px, tappable across 44px.
class ForgeCheckbox extends StatelessWidget {
  const ForgeCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  static const double size = 22;

  @override
  Widget build(BuildContext context) {
    final p = ForgeStyle.of(context).colors;
    return Semantics(
      checked: value,
      child: Pressable(
        onTap: () => onChanged(!value),
        height: size,
        width: size,
        builder: (context, _) => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: value ? p.accent : p.surface,
            borderRadius: BorderRadius.circular(
              _cupertino(context) ? size / 2 : 6,
            ),
            border: value ? null : Border.all(color: p.lineStrong, width: 2),
          ),
          child: value
              ? ForgeIcon(
                  ForgeIcons.check,
                  size: 14,
                  weight: 3.2,
                  color: p.onAccent,
                )
              : null,
        ),
      ),
    );
  }
}
