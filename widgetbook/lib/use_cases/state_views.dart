import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Loading', type: LoadingView)
Widget loadingView(BuildContext context) => const LoadingView();

@widgetbook.UseCase(name: 'Error', type: ErrorView)
Widget errorView(BuildContext context) => ErrorView(
  message: context.knobs.string(
    label: 'Message',
    initialValue: "Couldn't load this week",
  ),
  onRetry: () {},
);

@widgetbook.UseCase(name: 'Empty', type: EmptyView)
Widget emptyView(BuildContext context) => EmptyView(
  message: context.knobs.string(label: 'Message', initialValue: 'No items yet'),
  action: FilledButton(onPressed: () {}, child: const Text('Add item')),
);
