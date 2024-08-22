import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String savedColorKey = 'themeColor';

Future<Color?> getSavedColor() async {
  final prefs = await SharedPreferences.getInstance();
  final colorInt = prefs.getInt(savedColorKey);
  if (colorInt != null) {
    return Color(colorInt);
  }
  return null;
}

Future<void> saveColor(Color color) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(savedColorKey, color.value);
}
