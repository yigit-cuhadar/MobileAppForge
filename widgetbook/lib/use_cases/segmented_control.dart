import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Two options', type: ForgeSegmentedControl)
Widget twoOptions(BuildContext context) =>
    const _Segmented(labels: ['Overview', 'Compare']);

@widgetbook.UseCase(name: 'Three options', type: ForgeSegmentedControl)
Widget threeOptions(BuildContext context) =>
    const _Segmented(labels: ['Previous', 'First', 'Other date']);

@widgetbook.UseCase(name: 'Locked', type: ForgeSegmentedControl)
Widget locked(BuildContext context) => const _Segmented(
  labels: ['Option one', 'Option two', 'Option three'],
  locked: {1, 2},
);

class _Segmented extends StatefulWidget {
  const _Segmented({required this.labels, this.locked = const {}});

  final List<String> labels;
  final Set<int> locked;

  @override
  State<_Segmented> createState() => _SegmentedState();
}

class _SegmentedState extends State<_Segmented> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Gap.md),
      child: ForgeSegmentedControl<int>(
        segments: [
          for (final (i, label) in widget.labels.indexed)
            ForgeSegment(
              value: i,
              label: label,
              locked: widget.locked.contains(i),
            ),
        ],
        selected: _selected,
        onChanged: (i) => setState(() => _selected = i),
        onLocked: (_) => ScaffoldMessenger.maybeOf(context)
            ?.showSnackBar(const SnackBar(content: Text('Opens the paywall'))),
      ),
    ),
  );
}
