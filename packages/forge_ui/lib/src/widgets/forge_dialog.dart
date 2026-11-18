import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/forge_style.dart';
import 'list_row.dart';
import 'or_divider.dart';

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
    this.message,
    this.field,
    required this.action,
    this.alternative,
    required this.cancel,
  }) : list = null;

  /// The title over a list to choose from, such as [ListRow]s with
  /// checkboxes: the rows sit flush with the title, untinted, and the list
  /// scrolls between the title and the buttons, fading out at the bottom
  /// while more rows lie below.
  const ForgeDialog.list({
    super.key,
    required this.title,
    required List<Widget> this.list,
    required this.action,
    required this.cancel,
  }) : message = null,
       field = null,
       alternative = null;

  final String title;
  final String? message;

  /// One text field under the text.
  final Widget? field;
  final List<Widget>? list;
  final Widget action;

  /// Another way to do [action], between it and [cancel]: an [OrDivider]
  /// over sign-in buttons.
  final Widget? alternative;
  final Widget cancel;

  static const double maxWidth = 320;

  @override
  Widget build(BuildContext context) {
    final theme = DialogTheme.of(context);
    final heading = Text(
      title,
      textAlign: TextAlign.center,
      style: theme.titleTextStyle,
    );
    final buttons = [
      const SizedBox(height: 20),
      action,
      if (alternative case final alternative?) ...[
        const SizedBox(height: Gap.md),
        alternative,
      ],
      const SizedBox(height: Gap.sm),
      cancel,
    ];
    final list = this.list;
    return Dialog(
      insetPadding: const EdgeInsets.all(Gap.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: Semantics(
          namesRoute: true,
          scopesRoute: true,
          explicitChildNodes: true,
          label: title,
          child: list != null
              ? Padding(
                  padding: const EdgeInsets.all(Gap.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      heading,
                      const SizedBox(height: Gap.sm),
                      Flexible(
                        child: ListRowFlush(child: _FadingList(rows: list)),
                      ),
                      ...buttons,
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(Gap.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      heading,
                      if (message case final message?) ...[
                        const SizedBox(height: Gap.sm),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: theme.contentTextStyle,
                        ),
                      ],
                      if (field case final field?) ...[
                        const SizedBox(height: Gap.md),
                        field,
                      ],
                      ...buttons,
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// [rows] in a scroll view whose bottom fades into the dialog's surface
/// while more lies below.
class _FadingList extends StatefulWidget {
  const _FadingList({required this.rows});

  final List<Widget> rows;

  @override
  State<_FadingList> createState() => _FadingListState();
}

class _FadingListState extends State<_FadingList> {
  final _controller = ScrollController();
  bool _more = false;

  static const double _fade = 28;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    final more = position.extentAfter > 0;
    if (more != _more) setState(() => _more = more);
  }

  @override
  Widget build(BuildContext context) {
    final surface = ForgeStyle.of(context).colors.surface;
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        _check();
        return false;
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _controller,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: widget.rows,
            ),
          ),
          if (_more)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _fade,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [surface.withValues(alpha: 0), surface],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
