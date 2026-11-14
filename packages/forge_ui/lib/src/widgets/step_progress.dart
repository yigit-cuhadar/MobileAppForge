import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';

/// Where a step-by-step flow stands: a thin bar of [count] parts, the done
/// ones and the [current] one (from 1) in accent, and an optional
/// [caption] under it.
class StepProgress extends StatelessWidget {
  const StepProgress({
    super.key,
    required this.count,
    required this.current,
    this.caption,
  });

  final int count;
  final int current;
  final String? caption;

  static const double height = 4;

  @override
  Widget build(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    return Semantics(
      container: true,
      value: '$current/$count',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Gap.sm,
        children: [
          Row(
            spacing: Gap.xs,
            children: [
              for (var i = 1; i <= count; i++)
                Expanded(
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      color: i <= current ? colors.accent : colors.line,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                ),
            ],
          ),
          if (caption != null)
            Text(
              caption!,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.w400,
                color: colors.inkMuted,
              ),
            ),
        ],
      ),
    );
  }
}
