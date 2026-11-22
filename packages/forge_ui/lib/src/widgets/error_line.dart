import 'package:material_ui/material_ui.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';
import 'forge_button.dart';

/// A failure inside a card: the [message] in danger and an outline Retry
/// on one line.
class ErrorLine extends StatelessWidget {
  const ErrorLine({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Row(
    spacing: Gap.sm,
    children: [
      Expanded(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodySmall!
              .copyWith(color: ForgeStyle.of(context).colors.danger),
        ),
      ),
      ForgeButton(
        label: retryLabel,
        onPressed: onRetry,
        variant: ForgeButtonVariant.outline,
      ),
    ],
  );
}
