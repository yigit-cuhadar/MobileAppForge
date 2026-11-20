import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';

import 'app_gate_strings.dart';

/// In place of the app while its version is below the minimum: the one
/// way on is the store.
class UpdateRequiredPage extends StatelessWidget {
  const UpdateRequiredPage({
    super.key,
    required this.strings,
    required this.onUpdate,
  });

  final AppGateStrings strings;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: EmptyView(
        icon: ForgeIcons.getApp,
        title: strings.updateRequiredTitle,
        message: strings.updateRequiredMessage,
        actions: [ForgeButton(label: strings.update, onPressed: onUpdate)],
      ),
    ),
  );
}

/// In place of the app during maintenance, with [message] and a Retry
/// that is busy while [retrying].
class MaintenancePage extends StatelessWidget {
  const MaintenancePage({
    super.key,
    required this.strings,
    required this.message,
    required this.retrying,
    required this.onRetry,
  });

  final AppGateStrings strings;
  final String message;
  final bool retrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: EmptyView(
        icon: ForgeIcons.hourglassEmpty,
        title: strings.maintenanceTitle,
        message: message,
        actions: [
          ForgeButton(
            label: strings.retry,
            onPressed: onRetry,
            variant: ForgeButtonVariant.outline,
            loading: retrying,
          ),
        ],
      ),
    ),
  );
}

/// The content of the sheet offering a recommended version.
class UpdateAvailableSheet extends StatelessWidget {
  const UpdateAvailableSheet({
    super.key,
    required this.strings,
    required this.onUpdate,
    required this.onLater,
  });

  final AppGateStrings strings;
  final VoidCallback onUpdate;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) => ForgeBottomSheet(
    title: strings.updateAvailableTitle,
    action: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Gap.sm,
      children: [
        ForgeButton(
          label: strings.update,
          onPressed: onUpdate,
          size: ForgeButtonSize.large,
        ),
        ForgeButton(
          label: strings.later,
          onPressed: onLater,
          variant: ForgeButtonVariant.secondary,
          size: ForgeButtonSize.large,
        ),
      ],
    ),
    child: Text(
      strings.updateAvailableMessage,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );
}
