import 'package:flutter/material.dart';

import 'forge_bottom_sheet.dart';
import 'forge_button.dart';
import 'list_row.dart';

/// Shows a [ForgeCheckSheet] offering [values], [selected] ticked.
/// Completes with the ticked values once saved, in [values]' order, or null
/// when closed without saving. Opened from a sheet, it stacks over it and
/// returns to it.
Future<Set<T>?> showForgeCheckSheet<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required List<T> values,
  required Set<T> selected,
  required String Function(T value) labelOf,
  required String saveLabel,
}) => showForgeBottomSheet<Set<T>>(
  context: context,
  builder: (_) => ForgeCheckSheet<T>(
    title: title,
    subtitle: subtitle,
    values: values,
    selected: selected,
    labelOf: labelOf,
    saveLabel: saveLabel,
  ),
);

/// A [ForgeBottomSheet] listing [values] as [ListRow.check] rows, a line
/// between each two, scrolling when they do not fit, and a full-width
/// [saveLabel] button that closes it with the ticked values. The ticks stay
/// in the sheet until saved.
class ForgeCheckSheet<T> extends StatefulWidget {
  const ForgeCheckSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.saveLabel,
  });

  final String title;
  final String? subtitle;
  final List<T> values;

  /// The values ticked when the sheet opens.
  final Set<T> selected;
  final String Function(T value) labelOf;
  final String saveLabel;

  @override
  State<ForgeCheckSheet<T>> createState() => _ForgeCheckSheetState<T>();
}

class _ForgeCheckSheetState<T> extends State<ForgeCheckSheet<T>> {
  late final Set<T> _ticked = {...widget.selected};

  @override
  Widget build(BuildContext context) => ForgeBottomSheet(
    title: widget.title,
    subtitle: widget.subtitle,
    action: ForgeButton(
      label: widget.saveLabel,
      onPressed: () => Navigator.pop(context, {
        for (final value in widget.values)
          if (_ticked.contains(value)) value,
      }),
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, value) in widget.values.indexed) ...[
            if (i > 0) const Divider(),
            ListRow.check(
              title: widget.labelOf(value),
              checked: _ticked.contains(value),
              onChanged: (checked) => setState(
                () => checked ? _ticked.add(value) : _ticked.remove(value),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
