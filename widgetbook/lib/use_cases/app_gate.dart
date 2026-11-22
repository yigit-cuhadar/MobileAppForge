import 'package:material_ui/material_ui.dart';
import 'package:forge_app_gate/forge_app_gate.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

const _strings = AppGateStrings();

@widgetbook.UseCase(name: 'Update required', type: UpdateRequiredPage)
Widget updateRequiredPage(BuildContext context) =>
    UpdateRequiredPage(strings: _strings, onUpdate: () {});

@widgetbook.UseCase(name: 'Server message', type: MaintenancePage)
Widget maintenancePage(BuildContext context) => MaintenancePage(
  strings: _strings,
  message: context.knobs.string(
    label: 'Message',
    initialValue: "We're upgrading our servers. Back by [TIME].",
  ),
  retrying: false,
  onRetry: () {},
);

@widgetbook.UseCase(name: 'Default message', type: MaintenancePage)
Widget maintenancePageDefault(BuildContext context) => MaintenancePage(
  strings: _strings,
  message: _strings.maintenanceMessage,
  retrying: false,
  onRetry: () {},
);

@widgetbook.UseCase(name: 'Retrying', type: MaintenancePage)
Widget maintenancePageRetrying(BuildContext context) => MaintenancePage(
  strings: _strings,
  message: _strings.maintenanceMessage,
  retrying: true,
  onRetry: () {},
);

/// The sheet over the app's scrim, as [AppGate] shows it.
@widgetbook.UseCase(name: 'Update available', type: UpdateAvailableSheet)
Widget updateAvailableSheet(BuildContext context) => ColoredBox(
  color: Theme.of(context).colorScheme.scrim,
  child: Column(
    children: [
      const Spacer(),
      BottomSheet(
        onClosing: () {},
        enableDrag: false,
        builder: (_) => UpdateAvailableSheet(
          strings: _strings,
          onUpdate: () {},
          onLater: () {},
        ),
      ),
    ],
  ),
);
