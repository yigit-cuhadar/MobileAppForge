import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Five tabs', type: ForgeNavigationBar)
Widget navigationBar(BuildContext context) => Scaffold(
  bottomNavigationBar: ForgeNavigationBar(
    destinations: const [
      ForgeDestination(icon: ForgeIcons.home, label: '[TAB 1]'),
      ForgeDestination(icon: ForgeIcons.list, label: '[TAB 2]'),
      ForgeDestination(icon: ForgeIcons.search, label: '[TAB 3]'),
      ForgeDestination(icon: ForgeIcons.barChart, label: '[TAB 4]'),
      ForgeDestination(icon: ForgeIcons.person, label: '[TAB 5]'),
    ],
    selectedIndex: context.knobs.int.slider(
      label: 'Selected',
      initialValue: 0,
      max: 4,
    ),
    onSelected: (_) {},
  ),
);
