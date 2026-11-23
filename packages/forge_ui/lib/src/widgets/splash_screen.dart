import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../spacing.dart';
import 'forge_button.dart';
import 'runner_line.dart';

/// The app's start screen: its [mark] on a rounded tile with its [name]
/// under it, centred on the app's [background]; [foreground] is the colour
/// on it. No spinner: once [slowAfter] has passed, a thin indeterminate
/// line appears under the name. [SplashScreen.failed] keeps the mark and
/// the name and adds one [message] line and an outline Retry. A [logo]
/// that already holds the mark and its ground (the app's launch artwork)
/// takes the place of the tile and the name, which it then reads as.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.mark,
    required this.name,
    required this.background,
    required this.foreground,
    required Duration this.slowAfter,
    this.logo,
  }) : message = null,
       retryLabel = null,
       onRetry = null;

  const SplashScreen.failed({
    super.key,
    required this.mark,
    required this.name,
    required this.background,
    required this.foreground,
    required String this.message,
    required String this.retryLabel,
    required VoidCallback this.onRetry,
    this.logo,
  }) : slowAfter = null;

  /// Drawn in [background] on a 64px [foreground] tile.
  final Widget mark;
  final String name;

  /// Shown alone, [logoSize] square, in place of the mark's tile and the
  /// name.
  final Widget? logo;
  static const double logoSize = 240;
  final Color background;
  final Color foreground;
  final Duration? slowAfter;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _slow = false;

  static const double _tile = 64;
  static const double _tileRadius = 18;

  @override
  void initState() {
    super.initState();
    _startSlowTimer();
  }

  @override
  void didUpdateWidget(SplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A start after Retry is a new start: the slow line waits again.
    if (widget.slowAfter != oldWidget.slowAfter) {
      _timer?.cancel();
      _slow = false;
      _startSlowTimer();
    }
  }

  void _startSlowTimer() {
    final slowAfter = widget.slowAfter;
    _timer = slowAfter == null
        ? null
        : Timer(slowAfter, () => setState(() => _slow = true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final on = widget.foreground;
    final rest = [
      if (widget.onRetry case final onRetry?) ...[
        Padding(
          // The message stands apart from the name.
          padding: const EdgeInsets.only(top: Gap.lg),
          child: Text(
            widget.message!,
            textAlign: TextAlign.center,
            style: text.bodyLarge!.copyWith(height: 21 / 15, color: on),
          ),
        ),
        ForgeButton(
          label: widget.retryLabel!,
          onPressed: onRetry,
          variant: ForgeButtonVariant.outline,
        ),
      ] else if (_slow)
        RunnerLine(color: on, width: 96),
    ];
    final logo = widget.logo;
    if (logo != null) return _withLogo(logo, rest);
    final children = [
      Container(
        width: _tile,
        height: _tile,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on,
          borderRadius: BorderRadius.circular(_tileRadius),
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: widget.background),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: widget.background),
            child: widget.mark,
          ),
        ),
      ),
      Text(
        widget.name,
        textAlign: TextAlign.center,
        style: text.titleLarge!.copyWith(
          fontSize: 20,
          height: 1.2,
          letterSpacing: -0.2,
          color: on,
        ),
      ),
      ...rest,
    ];
    return ColoredBox(
      color: widget.background,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Gap.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: Gap.md,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  /// The logo stays in the middle of the whole screen, where a native
  /// launch screen draws it, so the handover does not move it; the slow
  /// line or the failure sits under it.
  Widget _withLogo(Widget logo, List<Widget> rest) => ColoredBox(
    color: widget.background,
    child: LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Center(
            child: Semantics(
              label: widget.name,
              child: SizedBox.square(
                dimension: SplashScreen.logoSize,
                child: ExcludeSemantics(child: logo),
              ),
            ),
          ),
          if (rest.isNotEmpty)
            Positioned(
              top: (constraints.maxHeight + SplashScreen.logoSize) / 2,
              left: Gap.lg,
              right: Gap.lg,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: Gap.md,
                children: rest,
              ),
            ),
        ],
      ),
    ),
  );
}
