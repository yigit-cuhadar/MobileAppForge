import 'package:flutter/material.dart';

import '../spacing.dart';

/// Shows a [ForgeDialog] over a scrim.
Future<T?> showForgeDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showDialog<T>(context: context, builder: builder);

/// A centred dialog: title, text, an optional field, then full-width
/// buttons stacked with the main (or danger) action on top and Cancel under
/// it. With a field, the main action keeps the dialog open on a bad value.
class ForgeDialog extends StatelessWidget {
  const ForgeDialog({
    super.key,
    required this.title,
    required this.message,
    this.field,
    required this.action,
    required this.cancel,
  });

  final String title;
  final String message;

  /// One text field under the text.
  final Widget? field;
  final Widget action;
  final Widget cancel;

  static const double maxWidth = 320;

  @override
  Widget build(BuildContext context) {
    final theme = DialogTheme.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(Gap.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: Semantics(
          namesRoute: true,
          scopesRoute: true,
          explicitChildNodes: true,
          label: title,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Gap.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.titleTextStyle,
                ),
                const SizedBox(height: Gap.sm),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.contentTextStyle,
                ),
                if (field case final field?) ...[
                  const SizedBox(height: Gap.md),
                  field,
                ],
                const SizedBox(height: 20),
                action,
                const SizedBox(height: Gap.sm),
                cancel,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
