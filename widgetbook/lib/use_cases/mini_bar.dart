import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Above the tabs', type: MiniBar)
Widget miniBar(BuildContext context) => Scaffold(
  bottomNavigationBar: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      MiniBar(
        icon: ForgeIcons.timer,
        title: context.knobs.string(
          label: 'Title',
          initialValue: 'Ongoing task',
        ),
        detail: context.knobs.string(
          label: 'Detail',
          initialValue: '1:45 left',
        ),
        onTap: () {},
      ),
      ForgeNavigationBar(
        destinations: const [
          ForgeDestination(icon: ForgeIcons.home, label: '[TAB 1]'),
          ForgeDestination(icon: ForgeIcons.list, label: '[TAB 2]'),
          ForgeDestination(icon: ForgeIcons.person, label: '[TAB 3]'),
        ],
        selectedIndex: 0,
        onSelected: (_) {},
      ),
    ],
  ),
);
