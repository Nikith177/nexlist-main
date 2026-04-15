// ignore: depend_on_referenced_packages
import 'package:characters/characters.dart';

String formatTitle(String? value) {
  final text = (value ?? '').trim();

  if (text.isEmpty) return '';

  final firstChar = text.characters.first;
  final rest = text.characters.skip(1).toString();

  return firstChar.toUpperCase() + rest;
}
