import 'package:flutter/material.dart';

abstract final class CureandoTheme {
  static const Color blue = Color(0xFF0D61EB);
  static const Color pink = Color(0xFFFF0091);
  static const Color yellow = Color(0xFFFFE100);
  static const Color green = Color(0xFF00C642);
  static const Color blueSoft = Color(0xFFEEF4FF);
  static const Color pinkSoft = Color(0xFFFFF0F8);
  static const Color yellowSoft = Color(0xFFFFFBEB);
  static const Color greenSoft = Color(0xFFECFDF5);
  static const Color background = Color(0xFFF8FAFC);
  static const Color ink = Color(0xFF0F172A);
  static const Color secondaryInk = Color(0xFF475569);

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    fontFamilyFallback: const <String>['Roboto', 'sans-serif'],
    colorScheme: ColorScheme.fromSeed(seedColor: blue).copyWith(
      primary: blue,
      onPrimary: Colors.white,
      secondary: pink,
      onSecondary: ink,
      surface: Colors.white,
      onSurface: ink,
    ),
    scaffoldBackgroundColor: background,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45),
      bodyMedium: TextStyle(fontSize: 16, height: 1.45),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    ),
  );

  static TextScaler readingScale(TextScaler system, {required bool large}) =>
      large ? _ReadingTextScaler(system) : system;
}

class _ReadingTextScaler extends TextScaler {
  const _ReadingTextScaler(this.system);
  final TextScaler system;

  @override
  double scale(double fontSize) => system.scale(fontSize) * 1.2;

  @override
  double get textScaleFactor => scale(14) / 14;
}
