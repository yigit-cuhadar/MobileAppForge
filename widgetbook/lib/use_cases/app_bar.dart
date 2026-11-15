import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// [bar] on a page pushed over another, so it shows back (or close).
Widget _pushed(ForgeAppBar bar, {bool close = false}) => Navigator(
  pages: [
    const MaterialPage<void>(child: SizedBox()),
    MaterialPage<void>(
      fullscreenDialog: close,
      child: Scaffold(appBar: bar),
    ),
  ],
  onDidRemovePage: (_) {},
);

@widgetbook.UseCase(name: 'Tab root', type: ForgeAppBar)
Widget tabRootAppBar(BuildContext context) => Scaffold(
  appBar: ForgeAppBar(
    title: context.knobs.string(label: 'Title', initialValue: 'Home'),
  ),
);

@widgetbook.UseCase(name: 'Pushed page with action', type: ForgeAppBar)
Widget pushedAppBar(BuildContext context) => _pushed(
  ForgeAppBar(
    title: context.knobs.string(label: 'Title', initialValue: 'Details'),
    actions: [ForgeAppBarAction.text(label: 'Edit', onPressed: () {})],
  ),
);

@widgetbook.UseCase(name: 'Long title', type: ForgeAppBar)
Widget longTitleAppBar(BuildContext context) => _pushed(
  ForgeAppBar(
    title: context.knobs.string(
      label: 'Title',
      initialValue: 'A long item title that wraps',
    ),
    actions: [
      ForgeAppBarAction.icon(
        icon: ForgeIcons.moreVert,
        label: 'More',
        onPressed: () {},
      ),
    ],
  ),
);

@widgetbook.UseCase(name: 'Disabled action', type: ForgeAppBar)
Widget disabledActionAppBar(BuildContext context) => _pushed(
  ForgeAppBar(
    title: 'New item',
    actions: [
      ForgeAppBarAction.text(
        label: 'Save',
        onPressed: context.knobs.boolean(label: 'Enabled') ? () {} : null,
      ),
    ],
  ),
);

@widgetbook.UseCase(name: 'Close', type: ForgeAppBar)
Widget closeAppBar(BuildContext context) =>
    _pushed(const ForgeAppBar(title: 'Section title'), close: true);

@widgetbook.UseCase(name: 'Count badge', type: ForgeAppBar)
Widget countAppBar(BuildContext context) => _pushed(
  ForgeAppBar(
    title: 'Item list',
    actions: [
      ForgeAppBarAction.icon(
        icon: ForgeIcons.tune,
        label: 'Filters',
        count: context.knobs.intOrNull.slider(
          label: 'Count',
          initialValue: 2,
          min: 1,
          max: 99,
        ),
        onPressed: () {},
      ),
    ],
  ),
);

/// The value form with a small action that shows its [loading] state.
Widget _valueBar(BuildContext context, {required bool loading}) => Scaffold(
  appBar: ForgeAppBar.value(
    leading: ForgeAppBarAction.icon(
      icon: ForgeIcons.expandMore,
      label: 'Minimise',
      onPressed: () {},
    ),
    value: context.knobs.string(label: 'Value', initialValue: '24:16'),
    subtitle: context.knobs.string(
      label: 'Subtitle',
      initialValue: 'Item title · [DETAIL]',
    ),
    actions: [
      ForgeButton(
        label: 'Done',
        size: ForgeButtonSize.small,
        loading: loading,
        onPressed: () {},
      ),
      ForgeAppBarAction.icon(
        icon: ForgeIcons.moreHoriz,
        label: 'More',
        onPressed: () {},
      ),
    ],
  ),
);

@widgetbook.UseCase(name: 'Value', type: ForgeAppBar)
Widget valueAppBar(BuildContext context) => _valueBar(context, loading: false);

@widgetbook.UseCase(name: 'Value · action loading', type: ForgeAppBar)
Widget valueLoadingAppBar(BuildContext context) =>
    _valueBar(context, loading: true);

@widgetbook.UseCase(name: 'Toggled icon', type: ForgeAppBar)
Widget toggledAppBar(BuildContext context) => const _Toggled();

class _Toggled extends StatefulWidget {
  const _Toggled();

  @override
  State<_Toggled> createState() => _ToggledState();
}

class _ToggledState extends State<_Toggled> {
  bool _on = true;

  @override
  Widget build(BuildContext context) => _pushed(
    ForgeAppBar(
      title: 'Item title',
      actions: [
        ForgeAppBarAction.icon(
          icon: ForgeIcons.star,
          label: 'Favourite',
          toggled: _on,
          onPressed: () => setState(() => _on = !_on),
        ),
        ForgeAppBarAction.icon(
          icon: ForgeIcons.moreHoriz,
          label: 'More',
          onPressed: () {},
        ),
      ],
    ),
  );
}
