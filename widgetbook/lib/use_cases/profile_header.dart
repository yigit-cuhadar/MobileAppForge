import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _page(Widget child) =>
    ListView(padding: const EdgeInsets.all(Gap.lg), children: [child]);

@widgetbook.UseCase(name: 'Signed in', type: ProfileHeader)
Widget signedInProfileHeader(BuildContext context) => _page(
  ProfileHeader(
    initials: context.knobs.string(label: 'Initials', initialValue: 'AB'),
    name: context.knobs.string(label: 'Name', initialValue: '[USER NAME]'),
    detail: context.knobs.string(
      label: 'Detail',
      initialValue: 'user@example.com · [DETAIL]',
    ),
    onTap: () {},
  ),
);

@widgetbook.UseCase(name: 'Guest', type: ProfileHeader)
Widget guestProfileHeader(BuildContext context) => _page(
  ProfileHeader.guest(
    name: 'Guest',
    detail: 'Create an account to keep your data',
    onTap: () {},
  ),
);
