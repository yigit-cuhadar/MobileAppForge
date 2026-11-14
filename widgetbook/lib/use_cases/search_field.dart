import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _padded(Widget child) => Center(
  child: Padding(padding: const EdgeInsets.all(Gap.md), child: child),
);

@widgetbook.UseCase(name: 'Empty', type: ForgeSearchField)
Widget empty(BuildContext context) => _padded(
  ForgeSearchField(hint: 'Search', clearLabel: 'Clear', onChanged: (_) {}),
);

@widgetbook.UseCase(name: 'Typing', type: ForgeSearchField)
Widget typing(BuildContext context) => _padded(
  ForgeSearchField(
    hint: 'Search',
    clearLabel: 'Clear',
    controller: TextEditingController(text: 'query'),
    onChanged: (_) {},
  ),
);

@widgetbook.UseCase(name: 'With filter button', type: ForgeSearchField)
Widget withFilters(BuildContext context) => _padded(
  ForgeSearchField(
    hint: 'Search',
    clearLabel: 'Clear',
    onChanged: (_) {},
    onFilters: () {},
    filtersLabel: 'Filters',
    activeFilters: context.knobs.int.slider(
      label: 'Active filters',
      initialValue: 2,
      max: 9,
    ),
  ),
);
