import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import 'brand_palette.dart';

Color parseHex(String hex) {
  var value = hex.replaceAll('#', '');
  if (value.length == 6) value = 'FF$value';
  return Color(int.parse(value, radix: 16));
}

TextTheme _textThemeFor(String family, TextTheme base) {
  switch (family) {
    case 'Tajawal':
      return GoogleFonts.tajawalTextTheme(base);
    case 'Amiri':
      return GoogleFonts.amiriTextTheme(base);
    case 'Noto Kufi Arabic':
      return GoogleFonts.notoKufiArabicTextTheme(base);
    default:
      return GoogleFonts.cairoTextTheme(base);
  }
}

ThemeData buildAppTheme(Branding branding, {required bool dark}) {
  final primary = parseHex(branding.primaryColor);
  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: dark ? BrandPalette.accent : BrandPalette.primary,
    surface: dark ? BrandPalette.darkSurface : Colors.white,
  );
  final base = dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  return base.copyWith(
    colorScheme: scheme,
    textTheme: _textThemeFor(branding.fontFamily, base.textTheme).apply(
      bodyColor: dark ? Colors.white : BrandPalette.ink,
      displayColor: dark ? Colors.white : BrandPalette.ink,
    ),
    scaffoldBackgroundColor: dark ? BrandPalette.darkBg : BrandPalette.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? BrandPalette.darkSurface : Colors.white,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: dark ? BrandPalette.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dark ? Colors.white12 : BrandPalette.border.withValues(alpha: 0.7)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BrandPalette.primary,
        foregroundColor: Colors.white,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: BrandPalette.primary,
        side: const BorderSide(color: BrandPalette.border),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: BrandPalette.primary),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: dark ? BrandPalette.darkCard : BrandPalette.tint,
      selectedColor: BrandPalette.primary,
      side: BorderSide.none,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? BrandPalette.darkCard : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: BrandPalette.primary, width: 1.4),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: dark ? BrandPalette.darkSurface : Colors.white,
      selectedIconTheme: const IconThemeData(color: BrandPalette.primary),
      selectedLabelTextStyle: const TextStyle(color: BrandPalette.primary, fontWeight: FontWeight.w700),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: BrandPalette.primary),
  );
}
