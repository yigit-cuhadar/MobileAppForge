import 'package:flutter/widgets.dart';

import '../theme/forge_theme.dart';

/// A control drawn smaller than [ForgeTheme.tapMin] that still takes taps
/// across a 44px band, and tells its [builder] while it is held down.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.height,
    this.width,
    required this.builder,
  });

  final VoidCallback? onTap;

  /// The drawn height; the band grows it to [ForgeTheme.tapMin].
  final double height;

  /// The drawn width when it is fixed; a narrow control grows to the band.
  final double? width;
  final Widget Function(BuildContext context, bool pressed) builder;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _press(bool pressed) {
    if (pressed != _pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    double band(double size) =>
        size < ForgeTheme.tapMin ? (ForgeTheme.tapMin - size) / 2 : 0;
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: enabled ? (_) => _press(true) : null,
      onTapUp: enabled ? (_) => _press(false) : null,
      onTapCancel: enabled ? () => _press(false) : null,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: band(widget.height),
          horizontal: widget.width == null ? 0 : band(widget.width!),
        ),
        child: widget.builder(context, _pressed && widget.onTap != null),
      ),
    );
  }
}
