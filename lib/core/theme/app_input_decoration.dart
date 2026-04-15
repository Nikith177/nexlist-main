import 'package:flutter/material.dart';

const Color _defaultInputFillColor = Color(0xFF1A2233);
const Color _defaultInputFocusColor = Color(0xFF3B82F6);
const EdgeInsets _defaultInputPadding = EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 14,
);

OutlineInputBorder _buildBorder(BorderSide borderSide) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: borderSide,
  );
}

InputDecoration buildInputDecoration(
  String hint, {
  Color fillColor = _defaultInputFillColor,
  Color focusColor = _defaultInputFocusColor,
  TextStyle? hintStyle,
  TextStyle? labelStyle,
  EdgeInsetsGeometry contentPadding = _defaultInputPadding,
  bool alignLabelWithHint = false,
  bool isDense = true,
  Widget? prefixIcon,
  BoxConstraints? prefixIconConstraints,
  Widget? suffixIcon,
  String? prefixText,
  TextStyle? prefixStyle,
  TextStyle? counterStyle,
}) {
  final focusedBorderSide = BorderSide(color: focusColor, width: 1.5);

  return InputDecoration(
    hintText: hint.isEmpty ? null : hint,
    filled: true,
    fillColor: fillColor,
    border: _buildBorder(BorderSide.none),
    enabledBorder: _buildBorder(BorderSide.none),
    focusedBorder: _buildBorder(focusedBorderSide),
    disabledBorder: _buildBorder(BorderSide.none),
    errorBorder: _buildBorder(BorderSide.none),
    focusedErrorBorder: _buildBorder(focusedBorderSide),
    isDense: isDense,
    contentPadding: contentPadding,
    hintStyle: hintStyle,
    labelStyle: labelStyle,
    alignLabelWithHint: alignLabelWithHint,
    prefixIcon: prefixIcon,
    prefixIconConstraints: prefixIconConstraints,
    suffixIcon: suffixIcon,
    prefixText: prefixText,
    prefixStyle: prefixStyle,
    counterStyle: counterStyle,
  );
}
