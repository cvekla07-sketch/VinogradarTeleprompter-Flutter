import 'package:flutter/material.dart';

const Color wineRed = Color(0xFF8B1A2D);
const Color goldDark = Color(0xFFB8860B);
const Color gold = Color(0xFFFFD700);
const Color danger = Color(0xFFE53935);

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: wineRed,
      brightness: Brightness.dark,
      primary: const Color(0xFFB5485A),
      secondary: goldDark,
      tertiary: const Color(0xFF6B8A5A),
    ),
  );
}

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: wineRed,
      brightness: Brightness.light,
      primary: wineRed,
      secondary: goldDark,
      tertiary: const Color(0xFF4A7A3A),
    ),
  );
}
