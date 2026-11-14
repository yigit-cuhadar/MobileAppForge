import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Within, above, below', type: BandBar)
Widget bandBars(BuildContext context) {
  final low = context.knobs.double.slider(label: 'Band low', initialValue: 0.4);
  final high = context.knobs.double.slider(
    label: 'Band high',
    initialValue: 0.8,
  );
  return ListView(
    padding: const EdgeInsets.all(Gap.md),
    children: [
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(
            spacing: Gap.md,
            children: [
              BandBar(
                label: 'Item one',
                valueLabel: '14',
                value: 0.56,
                low: low,
                high: high,
              ),
              BandBar(
                label: 'Item two',
                valueLabel: '22',
                value: 0.88,
                low: low,
                high: high,
              ),
              BandBar(
                label: 'Item three',
                valueLabel: '8',
                value: 0.32,
                low: low,
                high: high,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

@widgetbook.UseCase(name: 'Compact (in a SectionCard)', type: BandBar)
Widget compactBandBars(BuildContext context) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: const [
    Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(Gap.md),
        child: Column(
          spacing: Gap.sm,
          children: [
            BandBar.compact(
              label: 'Item one',
              valueLabel: '14',
              value: 0.56,
              low: 0.4,
              high: 0.8,
            ),
            BandBar.compact(
              label: 'Item two',
              valueLabel: '8',
              value: 0.32,
              low: 0.4,
              high: 0.8,
            ),
          ],
        ),
      ),
    ),
  ],
);

@widgetbook.UseCase(name: 'App fills', type: BandBar)
Widget bandBarFills(BuildContext context) {
  final colors = ForgeStyle.of(context).colors;
  // Any three roles the app picks; here info, success and danger.
  final fills = BandBarFills(
    below: colors.info,
    within: colors.success,
    above: colors.danger,
  );
  return ListView(
    padding: const EdgeInsets.all(Gap.md),
    children: [
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(
            spacing: Gap.md,
            children: [
              for (final (label, value, share) in [
                ('Item one', '14', 0.56),
                ('Item two', '22', 0.88),
                ('Item three', '8', 0.32),
              ])
                BandBar(
                  label: label,
                  valueLabel: value,
                  value: share,
                  low: 0.4,
                  high: 0.8,
                  fills: fills,
                ),
            ],
          ),
        ),
      ),
    ],
  );
}
