import 'package:flutter/material.dart';

/// A thin track with a runner crossing it again and again: work under way
/// whose end is unknown. Still while the platform asks for less motion.
class RunnerLine extends StatefulWidget {
  const RunnerLine({super.key, required this.color, this.width});

  final Color color;

  /// The track's length; the full width when null.
  final double? width;

  static const double height = 3;

  @override
  State<RunnerLine> createState() => _RunnerLineState();
}

class _RunnerLineState extends State<RunnerLine>
    with SingleTickerProviderStateMixin {
  late final _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final _runner = CurvedAnimation(parent: _run, curve: Curves.easeInOut);

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
        width: widget.width ?? double.infinity,
        height: RunnerLine.height,
        color: color.withValues(alpha: color.a * 0.24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return AnimatedBuilder(
              animation: _runner,
              builder: (context, child) => Stack(
                children: [
                  Positioned(
                    // The runner, 40% of the track, enters from the left and
                    // leaves on the right.
                    left: width * (-0.4 + 1.4 * _runner.value),
                    top: 0,
                    bottom: 0,
                    width: width * 0.4,
                    child: child!,
                  ),
                ],
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, borderRadius: _radius),
              ),
            );
          },
        ),
      ),
    );
  }
}
