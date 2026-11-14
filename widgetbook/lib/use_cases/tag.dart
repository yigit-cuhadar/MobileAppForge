import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _tag(BuildContext context, String label, ForgeTagKind kind) => Center(
  child: ForgeTag(
    context.knobs.string(label: 'Label', initialValue: label),
    kind: kind,
  ),
);

@widgetbook.UseCase(name: 'Neutral', type: ForgeTag)
Widget neutral(BuildContext context) =>
    _tag(context, 'Custom', ForgeTagKind.neutral);

@widgetbook.UseCase(name: 'Category', type: ForgeTag)
Widget category(BuildContext context) =>
    _tag(context, 'Group A', ForgeTagKind.category);

@widgetbook.UseCase(name: 'Record', type: ForgeTag)
Widget record(BuildContext context) =>
    _tag(context, 'Best', ForgeTagKind.record);

@widgetbook.UseCase(name: 'Source', type: ForgeTag)
Widget source(BuildContext context) =>
    _tag(context, '[SOURCE]', ForgeTagKind.source);

@widgetbook.UseCase(name: 'Premium', type: ForgeTag)
Widget premium(BuildContext context) =>
    _tag(context, 'Premium', ForgeTagKind.premium);
