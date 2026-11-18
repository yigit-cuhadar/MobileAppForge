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

@widgetbook.UseCase(name: 'Tap-only', type: ForgeSearchField)
Widget tapOnly(BuildContext context) =>
    _padded(ForgeSearchField.tapOnly(hint: 'Search', onTap: () {}));

@widgetbook.UseCase(name: 'Focused by the page', type: ForgeSearchField)
Widget focusedByPage(BuildContext context) => const _FocusedByPage();

class _FocusedByPage extends StatefulWidget {
  const _FocusedByPage();

  @override
  State<_FocusedByPage> createState() => _FocusedByPageState();
}

class _FocusedByPageState extends State<_FocusedByPage> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // A page waits for its route's slide-in; here, for the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _padded(
    ForgeSearchField(
      hint: 'Search',
      clearLabel: 'Clear',
      focusNode: _focus,
      onChanged: (_) {},
    ),
  );
}

@widgetbook.UseCase(name: 'Hero flight', type: ForgeSearchField)
Widget heroFlight(BuildContext context) => _padded(
  ForgeSearchField.tapOnly(
    hint: 'Search',
    heroTag: heroFlight,
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: const ForgeAppBar(title: 'Items'),
          body: Padding(
            padding: const EdgeInsets.all(Gap.md),
            child: ForgeSearchField(
              hint: 'Search',
              clearLabel: 'Clear',
              onChanged: (_) {},
              onFilters: () {},
              filtersLabel: 'Filters',
              heroTag: heroFlight,
            ),
          ),
        ),
      ),
    ),
  ),
);
