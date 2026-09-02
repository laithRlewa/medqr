import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import 'clinic_style.dart';

Color parseHex(String hex) {
  var value = hex.replaceAll('#', '');
  if (value.length == 6) value = 'FF$value';
  return Color(int.parse(value, radix: 16));
}

// درجات داكنة باردة مشتقّة من بترولي الشعار.
const _darkBg = Color(0xFF061A22);
const _darkSurface = Color(0xFF0B2731);
const _darkCard = Color(0xFF10333F);
const _darkField = Color(0xFF163D4A);

ThemeData buildAppTheme(Branding branding, {required bool dark}) {
  final primary = parseHex(branding.primaryColor);
  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: dark ? ClinicColors.accent : ClinicColors.primary,
    surface: dark ? _darkSurface : ClinicColors.card,
  );
  final base = dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  final text = GoogleFonts.tajawalTextTheme(base.textTheme).apply(
    bodyColor: dark ? Colors.white : ClinicColors.ink,
    displayColor: dark ? Colors.white : ClinicColors.ink,
  );
  return base.copyWith(
    colorScheme: scheme,
    textTheme: text,
    scaffoldBackgroundColor: dark ? _darkBg : ClinicColors.bg,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? _darkSurface : ClinicColors.bg,
      foregroundColor: dark ? Colors.white : ClinicColors.ink,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, fontFamily: 'Tajawal'),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: dark ? _darkCard : ClinicColors.card,
      shadowColor: ClinicColors.primaryDeep.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ClinicRadii.card)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ClinicColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ClinicRadii.button)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        textStyle: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ClinicColors.primary,
        side: const BorderSide(color: ClinicColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ClinicRadii.button)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: ClinicColors.primary),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: ClinicColors.tint,
      selectedColor: ClinicColors.primary,
      labelStyle: text.labelLarge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ClinicRadii.pill)),
      side: BorderSide.none,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? _darkField : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(ClinicRadii.pill), borderSide: const BorderSide(color: ClinicColors.border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(ClinicRadii.pill), borderSide: const BorderSide(color: ClinicColors.border)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ClinicRadii.pill),
        borderSide: const BorderSide(color: ClinicColors.primary, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: dark ? _darkSurface : Colors.white,
      selectedIconTheme: const IconThemeData(color: ClinicColors.primary),
      selectedLabelTextStyle: const TextStyle(color: ClinicColors.primary, fontWeight: FontWeight.w700, fontFamily: 'Tajawal'),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: ClinicColors.primary),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? ClinicColors.primary : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? ClinicColors.primary.withValues(alpha: 0.4) : null,
      ),
    ),
  );
}
