import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _card({String? tag}) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    PlanCard(
      title: '[APP NAME] Premium',
      tag: tag,
      benefits: const [
        '[PREMIUM FEATURE ONE]',
        '[PREMIUM FEATURE TWO]',
        '[PREMIUM FEATURE THREE]',
      ],
      actionLabel: 'Get Premium',
      onAction: () {},
    ),
  ],
);

@widgetbook.UseCase(name: 'With tag', type: PlanCard)
Widget planCardWithTag(BuildContext context) => _card(tag: '7 days free');

@widgetbook.UseCase(name: 'Without tag', type: PlanCard)
Widget planCardWithoutTag(BuildContext context) => _card();

/// At 3x text the tag goes under the title.
@widgetbook.UseCase(name: 'Large text', type: PlanCard)
Widget planCardLargeText(BuildContext context) =>
    MediaQuery.withClampedTextScaling(
      minScaleFactor: 3,
      maxScaleFactor: 3,
      child: _card(tag: '7 days free'),
    );
