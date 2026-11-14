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
