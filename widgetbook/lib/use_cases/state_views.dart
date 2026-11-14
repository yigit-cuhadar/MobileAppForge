import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _page(Widget child) =>
    ListView(padding: const EdgeInsets.all(Gap.md), children: [child]);

@widgetbook.UseCase(name: 'Loading', type: LoadingView)
Widget loadingView(BuildContext context) => _page(const LoadingView());

@widgetbook.UseCase(name: 'Error', type: ErrorView)
Widget errorView(BuildContext context) => _page(
  ErrorView(
    title: context.knobs.string(
      label: 'Title',
      initialValue: "Couldn't load this",
    ),
    message: context.knobs.string(
      label: 'Message',
      initialValue: 'Check your connection and try again.',
    ),
    onRetry: () {},
  ),
);

@widgetbook.UseCase(name: 'Empty', type: EmptyView)
Widget emptyView(BuildContext context) => _page(
  EmptyView(
    title: context.knobs.string(
      label: 'Title',
      initialValue: 'Nothing here yet',
    ),
    message: context.knobs.string(
      label: 'Message',
      initialValue: 'Items you add show up here.',
    ),
    actions: [ElevatedButton(onPressed: () {}, child: const Text('Browse'))],
  ),
);

@widgetbook.UseCase(name: 'Empty · two buttons', type: EmptyView)
Widget emptyViewTwoButtons(BuildContext context) => _page(
  EmptyView(
    title: 'Nothing here yet',
    message: 'Add one yourself or pick from the list.',
    actions: [
      FilledButton(onPressed: () {}, child: const Text('Add item')),
      ElevatedButton(onPressed: () {}, child: const Text('Browse')),
    ],
  ),
);

@widgetbook.UseCase(name: 'Empty · no button', type: EmptyView)
Widget emptyViewNoButton(BuildContext context) => _page(
  const EmptyView(
    icon: ForgeIcons.barChart,
    title: 'No data for this period',
    message: 'It fills in as you add items.',
  ),
);

@widgetbook.UseCase(name: 'Working', type: WorkingView)
Widget workingView(BuildContext context) => _page(
  const WorkingView(
    title: 'Preparing your item',
    message: 'This takes a few seconds.',
  ),
);

@widgetbook.UseCase(name: 'Default', type: SkeletonBar)
Widget skeletonBar(BuildContext context) => _page(
  SkeletonBar(
    widthFactor: context.knobs.double.slider(
      label: 'Width',
      initialValue: 0.6,
      min: 0.1,
    ),
    height: context.knobs.double.slider(
      label: 'Height',
      initialValue: 12,
      min: 8,
      max: 24,
    ),
  ),
);
