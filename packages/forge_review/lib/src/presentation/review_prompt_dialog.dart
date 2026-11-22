import 'package:material_ui/material_ui.dart';
import 'package:forge_ui/forge_ui.dart';

/// The text of the review prompt. The app writes it, with its name.
class ReviewPromptStrings {
  const ReviewPromptStrings({
    required this.title,
    required this.message,
    required this.yes,
    required this.no,
    required this.close,
    required this.thanksTitle,
    required this.thanksMessage,
    required this.writeToUs,
  });

  /// "Enjoying [APP NAME]?"
  final String title;
  final String message;
  final String yes;
  final String no;

  /// The ✕'s label, and the button that closes the thanks.
  final String close;
  final String thanksTitle;
  final String thanksMessage;
  final String writeToUs;
}

/// What the user answered; null when they closed the prompt.
enum ReviewAnswer {
  /// Yes: open the platform's review prompt.
  liked,

  /// Not really, then Write to us: open the app's feedback form.
  writeToUs,
}

/// Asks whether the user enjoys the app. "Yes" answers [ReviewAnswer.liked];
/// "Not really" turns the dialog into a thanks that offers
/// [ReviewAnswer.writeToUs] or Close.
Future<ReviewAnswer?> showReviewPrompt(
  BuildContext context,
  ReviewPromptStrings strings,
) => showForgeDialog<ReviewAnswer>(
  context: context,
  builder: (_) => ReviewPromptDialog(strings: strings),
);

class ReviewPromptDialog extends StatefulWidget {
  const ReviewPromptDialog({super.key, required this.strings});

  final ReviewPromptStrings strings;

  @override
  State<ReviewPromptDialog> createState() => _ReviewPromptDialogState();
}

class _ReviewPromptDialogState extends State<ReviewPromptDialog> {
  bool _unhappy = false;

  void _answer([ReviewAnswer? answer]) => Navigator.pop(context, answer);

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    if (_unhappy) {
      return ForgeDialog(
        title: strings.thanksTitle,
        message: strings.thanksMessage,
        action: ForgeButton(
          label: strings.writeToUs,
          onPressed: () => _answer(ReviewAnswer.writeToUs),
        ),
        cancel: ForgeButton(
          label: strings.close,
          onPressed: _answer,
          variant: ForgeButtonVariant.secondary,
        ),
      );
    }
    return ForgeDialog.choice(
      title: strings.title,
      message: strings.message,
      action: ForgeButton(
        label: strings.yes,
        onPressed: () => _answer(ReviewAnswer.liked),
      ),
      cancel: ForgeButton(
        label: strings.no,
        onPressed: () => setState(() => _unhappy = true),
        variant: ForgeButtonVariant.secondary,
      ),
      close: ForgeIconButton(
        icon: ForgeIcons.close,
        label: strings.close,
        onPressed: _answer,
      ),
    );
  }
}
