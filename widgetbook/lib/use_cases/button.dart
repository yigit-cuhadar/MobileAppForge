import 'package:flutter/material.dart';
import 'package:forge_ui/forge_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

Widget _button(
  BuildContext context, {
  required String label,
  ForgeButtonVariant variant = ForgeButtonVariant.primary,
  ForgeButtonSize size = ForgeButtonSize.regular,
  bool enabled = true,
  bool loading = false,
  bool locked = false,
}) => Center(
  child: Padding(
    padding: const EdgeInsets.all(Gap.md),
    child: ForgeButton(
      label: context.knobs.string(label: 'Label', initialValue: label),
      variant: variant,
      size: size,
      loading: loading,
      locked: locked,
      onPressed: enabled ? () {} : null,
    ),
  ),
);

@widgetbook.UseCase(name: 'Primary', type: ForgeButton)
Widget primary(BuildContext context) => _button(context, label: 'Start');

@widgetbook.UseCase(name: 'Primary disabled', type: ForgeButton)
Widget primaryDisabled(BuildContext context) =>
    _button(context, label: 'Save', enabled: false);

@widgetbook.UseCase(name: 'Primary loading', type: ForgeButton)
Widget primaryLoading(BuildContext context) =>
    _button(context, label: 'Saving', loading: true);

@widgetbook.UseCase(name: 'Secondary', type: ForgeButton)
Widget secondary(BuildContext context) => _button(
  context,
  label: 'Secondary action',
  variant: ForgeButtonVariant.secondary,
);

@widgetbook.UseCase(name: 'Secondary disabled', type: ForgeButton)
Widget secondaryDisabled(BuildContext context) => _button(
  context,
  label: 'Secondary action',
  variant: ForgeButtonVariant.secondary,
  enabled: false,
);

@widgetbook.UseCase(name: 'Text', type: ForgeButton)
Widget text(BuildContext context) =>
    _button(context, label: 'Skip', variant: ForgeButtonVariant.text);

@widgetbook.UseCase(name: 'Danger', type: ForgeButton)
Widget danger(BuildContext context) => _button(
  context,
  label: 'Discard changes',
  variant: ForgeButtonVariant.danger,
);

@widgetbook.UseCase(name: 'Danger disabled', type: ForgeButton)
Widget dangerDisabled(BuildContext context) => _button(
  context,
  label: 'Delete',
  variant: ForgeButtonVariant.danger,
  enabled: false,
);

@widgetbook.UseCase(name: 'Outline (Retry)', type: ForgeButton)
Widget outline(BuildContext context) =>
    _button(context, label: 'Retry', variant: ForgeButtonVariant.outline);

@widgetbook.UseCase(name: 'Small', type: ForgeButton)
Widget small(BuildContext context) => Center(
  child: Row(
    mainAxisSize: MainAxisSize.min,
    spacing: Gap.sm,
    children: [
      ForgeButton(
        label: 'Start',
        size: ForgeButtonSize.small,
        onPressed: () {},
      ),
      ForgeButton(
        label: 'Do it now',
        variant: ForgeButtonVariant.secondary,
        size: ForgeButtonSize.small,
        onPressed: () {},
      ),
    ],
  ),
);

@widgetbook.UseCase(name: 'Bottom of page', type: ForgeButton)
Widget bottomOfPage(BuildContext context) =>
    _button(context, label: 'Continue', size: ForgeButtonSize.large);

@widgetbook.UseCase(name: 'On a featured block', type: ForgeButton)
Widget onFeatured(BuildContext context) {
  final p = ForgeStyle.of(context).colors;
  final text = Theme.of(context).textTheme;
  return Center(
    child: Container(
      margin: const EdgeInsets.all(Gap.md),
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: p.featured,
        borderRadius: BorderRadius.circular(ForgeStyle.of(context).radii.lg),
        border: Border.all(
          color: p.featuredBorder,
          width: ForgeStyle.featuredBorder,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: Gap.md,
        children: [
          Text(
            'Item title',
            style: text.titleLarge!.copyWith(color: p.onFeatured),
          ),
          Row(
            spacing: Gap.sm,
            children: [
              Expanded(
                child: ForgeButton(
                  label: 'Start',
                  variant: ForgeButtonVariant.featured,
                  onPressed: () {},
                ),
              ),
              Expanded(
                child: ForgeButton(
                  label: 'Resume',
                  variant: ForgeButtonVariant.featured,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

@widgetbook.UseCase(name: 'Locked', type: ForgeButton)
Widget locked(BuildContext context) => Center(
  child: Padding(
    padding: const EdgeInsets.all(Gap.md),
    child: Row(
      spacing: Gap.sm,
      children: [
        Expanded(
          child: ForgeButton(label: 'Start', locked: true, onPressed: () {}),
        ),
        ForgeButton(
          label: 'Start',
          size: ForgeButtonSize.small,
          locked: true,
          onPressed: () {},
        ),
      ],
    ),
  ),
);

@widgetbook.UseCase(name: 'Add', type: ForgeAddButton)
Widget add(BuildContext context) => Center(
  child: Padding(
    padding: const EdgeInsets.all(Gap.md),
    child: ForgeAddButton(
      label: context.knobs.string(label: 'Label', initialValue: 'Add item'),
      onPressed: () {},
    ),
  ),
);

@widgetbook.UseCase(name: 'Trailing icon', type: ForgeButton)
Widget trailingIcon(BuildContext context) => Center(
  child: Padding(
    padding: const EdgeInsets.all(Gap.md),
    child: ForgeButton(
      label: context.knobs.string(
        label: 'Label',
        initialValue: 'Get [SYSTEM APP]',
      ),
      trailingIcon: ForgeIcons.openInNew,
      onPressed: () {},
    ),
  ),
);

@widgetbook.UseCase(name: 'Leading icon', type: ForgeButton)
Widget leadingIcon(BuildContext context) => Padding(
  padding: const EdgeInsets.all(Gap.md),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: Gap.md,
    children: [
      ForgeButton(
        label: context.knobs.string(label: 'Label', initialValue: 'Done'),
        size: ForgeButtonSize.large,
        leadingIcon: ForgeIcons.check,
        onPressed: () {},
      ),
      ForgeButton(
        label: 'Add item',
        variant: ForgeButtonVariant.text,
        size: ForgeButtonSize.small,
        leadingIcon: ForgeIcons.add,
        onPressed: () {},
      ),
    ],
  ),
);
