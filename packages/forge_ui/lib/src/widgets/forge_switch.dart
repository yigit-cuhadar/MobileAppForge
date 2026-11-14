import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../theme/forge_style.dart';
import 'pressable.dart';

bool _cupertino(BuildContext context) => switch (Theme.of(context).platform) {
  TargetPlatform.iOS || TargetPlatform.macOS => true,
  _ => false,
};

/// An on/off switch in the platform's look: the Material switch (outlined
/// off, filled on, the thumb grows) on Android, the iOS switch (filled
/// track, constant white thumb) on iOS. A tap flips it; the thumb can also
/// be dragged and lands on the side it is let go nearer. Null [onChanged]
/// disables it.
class ForgeSwitch extends StatefulWidget {
  const ForgeSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  State<ForgeSwitch> createState() => _ForgeSwitchState();
}

class _ForgeSwitchState extends State<ForgeSwitch> {
  /// The thumb's place while dragged: 0 off, 1 on.
  double? _drag;

  void _update(DragUpdateDetails details, double travel) => setState(
    () => _drag = ((_drag ?? 0) + details.primaryDelta! / travel).clamp(0, 1),
  );

  void _end() {
    final on = _drag! >= 0.5;
    setState(() => _drag = null);
    if (on != widget.value) widget.onChanged!(on);
  }

  @override
  Widget build(BuildContext context) {
    final p = ForgeStyle.of(context).colors;
    final value = widget.value;
    final enabled = widget.onChanged != null;
    final ios = _cupertino(context);
    final (width, height) = ios ? (50.0, 30.0) : (52.0, 32.0);
    final t = _drag ?? (value ? 1.0 : 0.0);
    final alignment = Alignment(t * 2 - 1, 0);
    final duration = _drag == null ? kThemeAnimationDuration : Duration.zero;
    final Widget track;
    if (ios) {
      track = Opacity(
        opacity: enabled ? 1 : 0.5,
        child: AnimatedContainer(
          duration: duration,
          width: width,
          height: height,
          padding: const EdgeInsets.all(2),
          alignment: alignment,
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
      // Off: a 14px thumb 6px from the border; on: 22px, 4px from it.
      final thumb = 14.0 + 8 * t;
      final edge = on ? p.accent : (enabled ? p.lineStrong : p.line);
      track = AnimatedContainer(
        duration: duration,
        width: width,
        height: height,
        padding: EdgeInsets.symmetric(horizontal: 6 - 2 * t),
        alignment: alignment,
        decoration: BoxDecoration(
          color: on ? p.accent : p.surface,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(color: edge, width: 2),
        ),
        child: AnimatedContainer(
          duration: duration,
          width: thumb,
          height: thumb,
          decoration: BoxDecoration(
            color: on ? p.onAccent : edge,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    final travel = width - height;
    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        excludeFromSemantics: true,
        onHorizontalDragStart: enabled
            ? (_) => setState(() => _drag = value ? 1 : 0)
            : null,
        onHorizontalDragUpdate: enabled ? (d) => _update(d, travel) : null,
        onHorizontalDragEnd: enabled ? (_) => _end() : null,
        onHorizontalDragCancel: enabled
            ? () => setState(() => _drag = null)
            : null,
        child: Pressable(
          onTap: enabled ? () => widget.onChanged!(!value) : null,
          height: height,
          width: width,
          builder: (context, _) => track,
        ),
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
