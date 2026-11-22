import 'package:material_ui/material_ui.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _values = [72.5, 72.1, 72.3, 71.6, 71.4, 71.1, 71.2, 70.9, 70.8, 70.6];

Widget _card(Widget child) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    Card(
      margin: EdgeInsets.zero,
      child: Padding(padding: const EdgeInsets.all(Gap.md), child: child),
    ),
  ],
);

@widgetbook.UseCase(name: 'Plain', type: TrendLine)
Widget plainTrendLine(BuildContext context) =>
    _card(const TrendLine(values: _values));

@widgetbook.UseCase(name: 'Scaled', type: TrendLine)
Widget scaledTrendLine(BuildContext context) => _card(
  const TrendLine.scaled(
    values: _values,
    highLabel: '72.5',
    lowLabel: '70.6',
    startLabel: 'Aug 26',
    endLabel: 'Nov 18',
    semanticLabel: '[VALUE], last 12 weeks',
  ),
);
