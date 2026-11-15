import 'package:flutter/material.dart';

/// A text field's decoration inside a Forge control that draws its own
/// frame: no fill, padding or border. `InputDecoration.collapsed` is not
/// enough, as the theme's enabled and focused borders still apply to it.
InputDecoration bareDecoration({String? hintText, TextStyle? hintStyle}) =>
    InputDecoration(
      isCollapsed: true,
      filled: false,
      contentPadding: EdgeInsets.zero,
      hintText: hintText,
      hintStyle: hintStyle,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
    );
