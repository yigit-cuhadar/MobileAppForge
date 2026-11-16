import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'photo_tile.dart';

Widget _page(Widget child) =>
    ListView(padding: const EdgeInsets.all(Gap.md), children: [child]);

List<BeforeAfterView> _views(
  ComparedPhoto before,
  ComparedPhoto after, {
  String? change = '[CHANGE]',
}) => [
  for (final view in ['View A', 'View B', 'View C'])
    BeforeAfterView(
      name: view,
      before: before,
      after: after,
      beforeDate: '[DATE]',
      afterDate: '[DATE]',
      change: change,
    ),
];

@widgetbook.UseCase(name: 'Compare', type: BeforeAfterSlider)
Widget beforeAfterSlider(BuildContext context) => _page(
  BeforeAfterSlider(
    views: _views(
      ComparedPhoto(placeholderLight),
      ComparedPhoto(placeholderDark),
      change: context.knobs.boolean(label: 'Change', initialValue: true)
          ? '[CHANGE]'
          : null,
    ),
    sliderLabel: 'Before and after',
    onLaterDateTap:
        context.knobs.boolean(
          label: 'Later date is a link',
          initialValue: false,
        )
        ? () {}
        : null,
  ),
);

@widgetbook.UseCase(name: 'One view', type: BeforeAfterSlider)
Widget beforeAfterOneView(BuildContext context) => _page(
  BeforeAfterSlider(
    views: [
      BeforeAfterView(
        name: 'View A',
        before: ComparedPhoto(placeholderLight),
        after: ComparedPhoto(placeholderDark),
        beforeDate: '[DATE]',
        afterDate: '[DATE]',
        change: '[CHANGE]',
      ),
    ],
    sliderLabel: 'Before and after',
  ),
);

@widgetbook.UseCase(name: 'Missing side', type: BeforeAfterSlider)
Widget beforeAfterMissing(BuildContext context) => _page(
  BeforeAfterSlider(
    views: _views(
      ComparedPhoto.missing(
        context.knobs.string(label: 'Text', initialValue: 'No photo'),
      ),
      ComparedPhoto(placeholderDark),
    ),
    sliderLabel: 'Before and after',
  ),
);

@widgetbook.UseCase(name: 'Fetching side', type: BeforeAfterSlider)
Widget beforeAfterFetching(BuildContext context) => _page(
  BeforeAfterSlider(
    views: _views(
      const ComparedPhoto.loading(),
      ComparedPhoto(placeholderDark),
    ),
    sliderLabel: 'Before and after',
  ),
);

@widgetbook.UseCase(name: 'Single', type: BeforeAfterSlider)
Widget beforeAfterSingle(BuildContext context) => _page(
  BeforeAfterSlider(
    views: [
      for (final view in ['View A', 'View B', 'View C'])
        BeforeAfterView.single(
          name: view,
          photo: ComparedPhoto(placeholderLight),
          date: '[DATE]',
        ),
    ],
    sliderLabel: 'Before and after',
  ),
);

@widgetbook.UseCase(name: 'Loading', type: BeforeAfterSlider)
Widget beforeAfterLoading(BuildContext context) =>
    _page(const BeforeAfterSlider.loading());
