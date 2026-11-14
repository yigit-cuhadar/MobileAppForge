import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _page(Widget child) => ListView(
  padding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
  children: [child],
);

@widgetbook.UseCase(name: 'Numbered', type: BenefitList)
Widget numberedBenefits(BuildContext context) => _page(
  const BenefitList.numbered([
    '[BENEFIT ONE]',
    '[BENEFIT TWO]',
    '[BENEFIT THREE]',
  ]),
);

@widgetbook.UseCase(name: 'Checked', type: BenefitList)
Widget checkedBenefits(BuildContext context) => _page(
  const BenefitList.checked([
    '[PREMIUM FEATURE ONE]',
    '[PREMIUM FEATURE TWO]',
    '[PREMIUM FEATURE THREE]',
  ]),
);
