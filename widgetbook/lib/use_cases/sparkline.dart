import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _page(Widget child) =>
    ListView(padding: const EdgeInsets.all(Gap.md), children: [child]);

@widgetbook.UseCase(name: 'Filled', type: Sparkline)
Widget filledSparkline(BuildContext context) => _page(
  Sparkline(
    title: context.knobs.string(label: 'Title', initialValue: 'Trend'),
    onTap: () {},
    figure: '[VALUE]',
    caption: '[DETAIL] · Nov 10',
    values: const [92, 91, 89, 90, 86, 85, 82, 83, 80, 78, 77, 75],
    startLabel: '12 weeks ago · [VALUE]',
    endLabel: 'now · [VALUE]',
    semanticLabel: 'Value over the last 12 weeks',
  ),
);

@widgetbook.UseCase(name: 'Empty', type: Sparkline)
Widget emptySparkline(BuildContext context) => _page(
  Sparkline.empty(
    title: 'Trend',
    figure: context.knobs.boolean(label: 'One entry', initialValue: true)
        ? '[VALUE]'
        : null,
    message: 'Add one more entry to see the trend',
  ),
);

@widgetbook.UseCase(name: 'Loading', type: Sparkline)
Widget loadingSparkline(BuildContext context) =>
    _page(const Sparkline.loading(title: 'Trend'));

@widgetbook.UseCase(name: 'Error', type: Sparkline)
Widget errorSparkline(BuildContext context) => _page(
  Sparkline.error(
    title: 'Trend',
    message: "Couldn't load the trend",
    onRetry: () {},
    retryLabel: 'Retry',
  ),
);
