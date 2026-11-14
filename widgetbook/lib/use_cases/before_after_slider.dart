import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'photo_tile.dart';

@widgetbook.UseCase(name: 'Compare', type: BeforeAfterSlider)
Widget beforeAfterSlider(BuildContext context) => ListView(
  padding: const EdgeInsets.all(Gap.md),
  children: [
    BeforeAfterSlider(
      views: [
        for (final view in ['View A', 'View B', 'View C'])
          BeforeAfterView(
            name: view,
            before: placeholderLight,
            after: placeholderDark,
            beforeDate: '[DATE]',
            afterDate: '[DATE]',
            change: '[CHANGE]',
          ),
      ],
    ),
  ],
);
