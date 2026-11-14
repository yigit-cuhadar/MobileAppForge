import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// [bar] at the bottom of a page.
Widget _page(ForgeBottomActionBar bar) =>
    Scaffold(body: const SizedBox(), bottomNavigationBar: bar);

/// Button's 48px bottom-of-page forms.
Widget _primary(String label, {bool enabled = true, bool loading = false}) =>
    ForgeButton(
      label: label,
      onPressed: enabled ? () {} : null,
      loading: loading,
      size: ForgeButtonSize.large,
    );

Widget _secondary(String label) => ForgeButton(
  label: label,
  onPressed: () {},
  variant: ForgeButtonVariant.secondary,
  size: ForgeButtonSize.large,
);

@widgetbook.UseCase(name: 'One action', type: ForgeBottomActionBar)
Widget oneActionBar(BuildContext context) =>
    _page(ForgeBottomActionBar(primary: _primary('Save')));

@widgetbook.UseCase(name: 'Two side by side', type: ForgeBottomActionBar)
Widget sideBySideBar(BuildContext context) => _page(
  ForgeBottomActionBar.sideBySide(
    secondary: _secondary('Back'),
    primary: _primary('Next'),
  ),
);

@widgetbook.UseCase(name: 'Two stacked', type: ForgeBottomActionBar)
Widget stackedBar(BuildContext context) => _page(
  ForgeBottomActionBar.stacked(
    primary: _primary('Done'),
    secondary: _secondary('Save as copy'),
  ),
);

@widgetbook.UseCase(name: 'Disabled', type: ForgeBottomActionBar)
Widget disabledBar(BuildContext context) =>
    _page(ForgeBottomActionBar(primary: _primary('Save', enabled: false)));

@widgetbook.UseCase(name: 'Saving', type: ForgeBottomActionBar)
Widget savingBar(BuildContext context) =>
    _page(ForgeBottomActionBar(primary: _primary('Saving', loading: true)));

@widgetbook.UseCase(name: 'Count', type: ForgeBottomActionBar)
Widget countBar(BuildContext context) {
  final count = context.knobs.int.slider(
    label: 'Chosen',
    initialValue: 3,
    min: 1,
    max: 9,
  );
  return _page(
    ForgeBottomActionBar.count(count: '$count chosen', action: _primary('Add')),
  );
}

@widgetbook.UseCase(name: 'Count, none chosen', type: ForgeBottomActionBar)
Widget noneChosenBar(BuildContext context) => _page(
  ForgeBottomActionBar.count(
    count: 'None chosen',
    none: true,
    action: _primary('Add', enabled: false),
  ),
);
