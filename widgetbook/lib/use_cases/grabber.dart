import 'package:material_ui/material_ui.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Above the header of a page risen from the bottom; a sheet's own is in
/// its use cases.
@widgetbook.UseCase(name: 'Over a header', type: ForgeGrabber)
Widget grabber(BuildContext context) => const Scaffold(
  body: SafeArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(top: Gap.sm),
          child: ForgeGrabber(),
        ),
        ForgeAppBar(title: 'Page title'),
      ],
    ),
  ),
);
