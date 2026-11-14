import 'dart:async';

import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import 'forge_button.dart';

/// The app's start screen: its [mark] on a rounded tile with its [name]
/// under it, centred on the app's [background]; [foreground] is the colour
/// on it. No spinner: once [slowAfter] has passed, a thin indeterminate
/// line appears under the name. [SplashScreen.failed] is the "Couldn't
/// start" look on the same background, with Retry.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required Widget this.mark,
    required String this.name,
    required this.background,
    required this.foreground,
    required Duration this.slowAfter,
  }) : title = null,
       message = null,
       retryLabel = null,
       onRetry = null;

  const SplashScreen.failed({
    super.key,
    required this.background,
    required this.foreground,
    required String this.title,
    required String this.message,
    required String this.retryLabel,
    required VoidCallback this.onRetry,
  }) : mark = null,
       name = null,
       slowAfter = null;

  /// Drawn in [background] on a 64px [foreground] tile.
  final Widget? mark;
  final String? name;
  final Color background;
  final Color foreground;
  final Duration? slowAfter;
  final String? title;
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
  static const double _errorCircle = 44;

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
    final List<Widget> children;
    if (widget.onRetry case final onRetry?) {
      children = [
        Container(
          width: _errorCircle,
          height: _errorCircle,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on.withValues(alpha: on.a * 0.14),
          ),
          child: ForgeIcon(ForgeIcons.error, size: 22, color: on),
        ),
        Column(
          spacing: Gap.xs,
          children: [
            Text(
              widget.title!,
              textAlign: TextAlign.center,
              style: text.titleMedium!.copyWith(color: on),
            ),
            Text(
              widget.message!,
              textAlign: TextAlign.center,
              style: text.bodySmall!.copyWith(
                color: on.withValues(alpha: on.a * 0.72),
              ),
            ),
          ],
        ),
        ForgeButton(
          label: widget.retryLabel!,
          onPressed: onRetry,
          variant: ForgeButtonVariant.featured,
        ),
      ];
    } else {
      children = [
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
              child: widget.mark!,
            ),
          ),
        ),
        Text(
          widget.name!,
          textAlign: TextAlign.center,
          style: text.titleLarge!.copyWith(
            fontSize: 20,
            height: 1.2,
            letterSpacing: -0.2,
            color: on,
          ),
        ),
        if (_slow) _SlowLine(color: on),
      ];
    }
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
}

/// A thin track with a runner crossing it, for a start that takes long.
class _SlowLine extends StatefulWidget {
  const _SlowLine({required this.color});

  final Color color;

  @override
  State<_SlowLine> createState() => _SlowLineState();
}

class _SlowLineState extends State<_SlowLine>
    with SingleTickerProviderStateMixin {
  late final _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final _runner = CurvedAnimation(parent: _run, curve: Curves.easeInOut);

  static const double _width = 96;
  static const double _height = 3;
  static const _radius = BorderRadius.all(Radius.circular(2));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _run.stop();
    } else if (!_run.isAnimating) {
      _run.repeat();
    }
  }

  @override
  void dispose() {
    _runner.dispose();
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return ClipRRect(
      borderRadius: _radius,
      child: Container(
        width: _width,
        height: _height,
        color: color.withValues(alpha: color.a * 0.24),
        child: AnimatedBuilder(
          animation: _runner,
          builder: (context, child) => Stack(
            children: [
              Positioned(
                // The runner, 40% of the track, enters from the left and
                // leaves on the right.
                left: _width * (-0.4 + 1.4 * _runner.value),
                top: 0,
                bottom: 0,
                width: _width * 0.4,
                child: child!,
              ),
            ],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, borderRadius: _radius),
          ),
        ),
      ),
    );
  }
}
