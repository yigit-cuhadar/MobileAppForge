import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: OrDivider)
Widget orDivider(BuildContext context) => Padding(
  padding: const EdgeInsets.all(Gap.lg),
  child: Align(
    alignment: Alignment.topCenter,
    child: OrDivider(
      label: context.knobs.string(label: 'Label', initialValue: 'or'),
    ),
  ),
);
