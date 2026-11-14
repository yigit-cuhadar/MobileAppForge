import 'package:flutter/material.dart';

import '../icons/forge_icon.dart';
import '../icons/forge_icons.dart';
import '../spacing.dart';
import '../theme/forge_style.dart';
import 'card_frame.dart';
import 'forge_button.dart';
import 'progress.dart';
import 'skeleton.dart';

/// A figure in a tile: the SectionCard title row ([title], [detail],
/// chevron; the tile opens its page) with the [figure], its [unit] and a
/// [caption] under it, and an optional bar at the bottom filled to
/// [progress], from 0 to 1.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required String this.title,
    this.detail,
    required VoidCallback this.onTap,
    required String this.figure,
    this.unit,
    required String this.caption,
    this.progress,
  }) : _form = _Form.tile,
       change = null,
       changeIsGood = false,
       message = null,
       onRetry = null,
       retryLabel = null;

  /// No title row, just the [figure] with its [unit] and the [caption];
  /// not a tap target.
  const StatTile.figure({
    super.key,
    required String this.figure,
    this.unit,
    required String this.caption,
  }) : _form = _Form.figure,
       title = null,
       detail = null,
       onTap = null,
       progress = null,
       change = null,
       changeIsGood = false,
       message = null,
       onRetry = null,
       retryLabel = null;

  /// A small tile: the [label], the [figure] and a [change] line in data,
  /// success when it goes the way the app calls good ([changeIsGood]),
  /// danger when not.
  const StatTile.compact({
    super.key,
    required String label,
    required String this.figure,
    required String this.change,
    required this.changeIsGood,
  }) : _form = _Form.compact,
       title = label,
       detail = null,
       onTap = null,
       unit = null,
       caption = null,
       progress = null,
       message = null,
       onRetry = null,
       retryLabel = null;

  /// Two points in time: the [label], the [change] large and [fromTo]
  /// ("old → new") under it in ink-muted.
  const StatTile.change({
    super.key,
    required String label,
    required String this.change,
    required String fromTo,
  }) : _form = _Form.change,
       title = label,
       caption = fromTo,
       detail = null,
       onTap = null,
       figure = null,
       unit = null,
       progress = null,
       changeIsGood = false,
       message = null,
       onRetry = null,
       retryLabel = null;

  /// The title row stays; the figure and caption shimmer.
  const StatTile.loading({
    super.key,
    required String this.title,
    this.detail,
    required VoidCallback this.onTap,
  }) : _form = _Form.loading,
       figure = null,
       unit = null,
       caption = null,
       progress = null,
       change = null,
       changeIsGood = false,
       message = null,
       onRetry = null,
       retryLabel = null;

  /// Nothing yet: a dash for the figure and one muted [message].
  const StatTile.empty({
    super.key,
    required String this.title,
    this.detail,
    required VoidCallback this.onTap,
    required String this.message,
  }) : _form = _Form.empty,
       figure = null,
       unit = null,
       caption = null,
       progress = null,
       change = null,
       changeIsGood = false,
       onRetry = null,
       retryLabel = null;

  /// Loading failed: a dash for the figure, the [message] in danger and an
  /// outline Retry.
  const StatTile.error({
    super.key,
    required String this.title,
    this.detail,
    required VoidCallback this.onTap,
    required String this.message,
    required VoidCallback this.onRetry,
    String this.retryLabel = 'Retry',
  }) : _form = _Form.error,
       figure = null,
       unit = null,
       caption = null,
       progress = null,
       change = null,
       changeIsGood = false;

  final String? title;
  final String? detail;
  final VoidCallback? onTap;
  final String? figure;
  final String? unit;
  final String? caption;

  /// How far the bar under the caption is filled, from 0 to 1.
  final double? progress;

  /// Written with a true minus sign.
  final String? change;
  final bool changeIsGood;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final _Form _form;

  @override
  Widget build(BuildContext context) {
    final style = ForgeStyle.of(context);
    final colors = style.colors;
    final text = Theme.of(context).textTheme;
    final small = text.labelMedium!.copyWith(
      color: colors.inkMuted,
      fontWeight: FontWeight.w400,
    );
    final dash = Text('—', style: _figureStyle(text, colors.inkSubtle));

    switch (_form) {
      case _Form.compact || _Form.change:
        final compact = _form == _Form.compact;
        final value = compact ? figure! : _minus(change!);
        final column = Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Gap.md,
            vertical: Gap.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                title!,
                style: text.labelSmall!.copyWith(
                  color: colors.inkMuted,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                value,
                style: text.titleLarge!.copyWith(letterSpacing: -0.34),
              ),
              Text(
                compact ? _minus(change!) : caption!,
                style: style.data.copyWith(
                  fontSize: 11,
                  color: !compact
                      ? colors.inkMuted
                      : changeIsGood
                      ? colors.success
                      : colors.danger,
                ),
              ),
            ],
          ),
        );
        if (compact) return CardFrame(child: column);
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(style.radii.md),
            border: Border.all(color: colors.line),
          ),
          child: column,
        );
      case _Form.tile || _Form.figure:
        return _frame(
          gap: Gap.xs,
          children: [
            if (_form == _Form.tile) _titleRow(context),
            _figureRow(context, Text(figure!, style: _figureStyle(text))),
            Text(caption!, style: small),
            if (progress != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Progress.track(value: progress!),
              ),
          ],
        );
      case _Form.loading:
        return _frame(
          gap: Gap.md,
          children: [
            _titleRow(context),
            const SkeletonBar(widthFactor: 0.5, height: 22),
            const SkeletonBar(widthFactor: 0.7, height: 10),
          ],
        );
      case _Form.empty:
        return _frame(
          gap: Gap.md,
          children: [
            _titleRow(context),
            dash,
            Text(message!, style: small),
          ],
        );
      case _Form.error:
        return _frame(
          gap: Gap.xs,
          children: [
            _titleRow(context),
            _figureRow(context, dash),
            Text(message!, style: small.copyWith(color: colors.danger)),
            Padding(
              padding: const EdgeInsets.only(top: Gap.xs),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: ForgeButton(
                  label: retryLabel!,
                  onPressed: onRetry,
                  variant: ForgeButtonVariant.outline,
                ),
              ),
            ),
          ],
        );
    }
  }

  static TextStyle _figureStyle(TextTheme text, [Color? color]) =>
      text.titleMedium!.copyWith(
        fontSize: 24,
        height: 32 / 24,
        letterSpacing: -0.72,
        color: color,
      );

  /// A hyphen-minus in a change becomes the true minus sign.
  static String _minus(String change) => change.replaceAll('-', '−');

  Widget _frame({required double gap, required List<Widget> children}) {
    final body = Padding(
      padding: const EdgeInsets.all(Gap.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: gap,
        children: children,
      ),
    );
    return CardFrame(
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }

  Widget _titleRow(BuildContext context) {
    final colors = ForgeStyle.of(context).colors;
    final text = Theme.of(context).textTheme;
    return Row(
      spacing: Gap.xs,
      children: [
        Expanded(child: Text(title!, style: text.titleMedium)),
        if (detail != null)
          Text(
            detail!,
            style: text.labelMedium!.copyWith(
              color: colors.inkMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ForgeIcon(ForgeIcons.chevronRight, size: 16, color: colors.inkMuted),
      ],
    );
  }

  Widget _figureRow(BuildContext context, Widget figure) => Row(
    crossAxisAlignment: CrossAxisAlignment.baseline,
    textBaseline: TextBaseline.alphabetic,
    spacing: Gap.xs,
    children: [
      Flexible(child: figure),
      if (unit != null)
        Text(unit!, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

enum _Form { tile, figure, compact, change, loading, empty, error }
