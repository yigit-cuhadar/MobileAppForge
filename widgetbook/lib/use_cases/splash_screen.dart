import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// A placeholder mark: a rounded outline square.
class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) => Container(
    width: 26,
    height: 26,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: IconTheme.of(context).color!, width: 3),
    ),
  );
}

SplashScreen _starting(BuildContext context, Duration slowAfter) {
  final colors = ForgeStyle.of(context).colors;
  return SplashScreen(
    mark: const _Mark(),
    name: context.knobs.string(label: 'Name', initialValue: '[APP NAME]'),
    background: colors.featured,
    foreground: colors.onFeatured,
    slowAfter: slowAfter,
  );
}

@widgetbook.UseCase(name: 'Starting', type: SplashScreen)
Widget startingSplash(BuildContext context) =>
    _starting(context, const Duration(days: 1));

@widgetbook.UseCase(name: 'Slow start', type: SplashScreen)
Widget slowSplash(BuildContext context) => _starting(context, Duration.zero);

@widgetbook.UseCase(name: "Couldn't start", type: SplashScreen)
Widget failedSplash(BuildContext context) {
  final colors = ForgeStyle.of(context).colors;
  return SplashScreen.failed(
    background: colors.featured,
    foreground: colors.onFeatured,
    title: "Couldn't start",
    message: 'Check your connection and try again.',
    retryLabel: 'Retry',
    onRetry: () {},
  );
}
