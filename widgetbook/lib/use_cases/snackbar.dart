import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// [snackbar] where [showForgeSnackbar] puts it, with a button to show it.
Widget _shown(ForgeSnackbar snackbar) => Scaffold(
  body: Builder(
    builder: (context) => Center(
      child: ForgeButton(
        label: 'Show',
        onPressed: () => showForgeSnackbar(
          context,
          message: snackbar.message,
          actionLabel: snackbar.actionLabel,
          onAction: snackbar.onAction,
          error: snackbar.error,
        ),
      ),
    ),
  ),
  bottomNavigationBar: Padding(
    padding: const EdgeInsets.all(Gap.md),
    child: snackbar,
  ),
);

@widgetbook.UseCase(name: 'Info', type: ForgeSnackbar)
Widget infoSnackbar(BuildContext context) => _shown(
  ForgeSnackbar(
    message: context.knobs.string(label: 'Message', initialValue: 'Saved'),
  ),
);

@widgetbook.UseCase(name: 'Undo', type: ForgeSnackbar)
Widget undoSnackbar(BuildContext context) => _shown(
  ForgeSnackbar(message: 'Item removed', actionLabel: 'Undo', onAction: () {}),
);

@widgetbook.UseCase(name: 'Error', type: ForgeSnackbar)
Widget errorSnackbar(BuildContext context) => _shown(
  ForgeSnackbar(
    message: "Couldn't save. Check your connection.",
    actionLabel: 'Retry',
    onAction: () {},
    error: true,
  ),
);
