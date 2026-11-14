import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Tiles two to a row, as the card draws them.
Widget _grid(List<Widget> tiles) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    for (var i = 0; i < tiles.length; i += 2) ...[
      if (i > 0) const SizedBox(height: Gap.sm),
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Gap.sm,
          children: [
            Expanded(child: tiles[i]),
            Expanded(
              child: i + 1 < tiles.length
                  ? tiles[i + 1]
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    ],
  ],
);

@widgetbook.UseCase(name: 'Tile', type: StatTile)
Widget tileStatTile(BuildContext context) => _grid([
  StatTile(
    title: context.knobs.string(label: 'Title', initialValue: 'Metric A'),
    detail: 'This week',
    onTap: () {},
    figure: '95',
    unit: 'min',
    caption: '3 entries',
  ),
  StatTile(
    title: 'Metric B',
    detail: 'Today',
    onTap: () {},
    figure: '640',
    caption: 'of 1,000',
    progress: 0.64,
  ),
]);

@widgetbook.UseCase(name: 'Compact', type: StatTile)
Widget compactStatTile(BuildContext context) => _grid(const [
  StatTile.compact(
    label: 'Value A',
    figure: '82.4 [UNIT]',
    change: '-1.7',
    changeIsGood: true,
  ),
  StatTile.compact(
    label: 'Value B',
    figure: '88.5 [UNIT]',
    change: '-3.5',
    changeIsGood: true,
  ),
  StatTile.compact(
    label: 'Value C',
    figure: '105 [UNIT]',
    change: '+1.0',
    changeIsGood: false,
  ),
  StatTile.compact(
    label: 'Value D',
    figure: '12,400 [UNIT]',
    change: '+6%',
    changeIsGood: true,
  ),
]);

@widgetbook.UseCase(name: 'Change', type: StatTile)
Widget changeStatTile(BuildContext context) => _grid(const [
  StatTile.change(
    label: 'Value A',
    change: '-1.7',
    fromTo: '84.1 → 82.4 [UNIT]',
  ),
  StatTile.change(label: 'Value B', change: '-3.5', fromTo: '92 → 88.5 [UNIT]'),
]);

@widgetbook.UseCase(name: 'Figure only', type: StatTile)
Widget figureStatTile(BuildContext context) => _grid(const [
  StatTile.figure(figure: '5.2', unit: '[UNIT]', caption: '[DETAIL]'),
  StatTile.figure(figure: '38', unit: '[UNIT]', caption: '[DETAIL]'),
]);

@widgetbook.UseCase(name: 'Loading', type: StatTile)
Widget loadingStatTile(BuildContext context) => _grid([
  StatTile.loading(title: 'Metric A', detail: 'This week', onTap: () {}),
  StatTile.loading(title: 'Metric B', detail: 'Today', onTap: () {}),
]);

@widgetbook.UseCase(name: 'Empty', type: StatTile)
Widget emptyStatTile(BuildContext context) => _grid([
  StatTile.empty(
    title: 'Metric A',
    detail: 'This week',
    onTap: () {},
    message: 'Nothing yet',
  ),
  StatTile.empty(
    title: 'Metric B',
    detail: 'Today',
    onTap: () {},
    message: 'Connect a source',
  ),
]);

@widgetbook.UseCase(name: 'Error', type: StatTile)
Widget errorStatTile(BuildContext context) => _grid([
  StatTile.error(
    title: 'Metric A',
    detail: 'This week',
    onTap: () {},
    message: "Couldn't load",
    onRetry: () {},
    retryLabel: 'Retry',
  ),
]);
