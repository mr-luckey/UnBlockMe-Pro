import 'package:blocked/storage/storage.dart';
import 'package:flutter/material.dart';

const String savedColorKey = 'themeColor';

Future<Color?> getSavedColor() async {
  final colorInt = getInt(savedColorKey);
  if (colorInt != null) {
    return Color(colorInt);
  }
  return null;
}

Future<void> saveColor(Color color) async {
  await setInt(savedColorKey, color.value);
}
