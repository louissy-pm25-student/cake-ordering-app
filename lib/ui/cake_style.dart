import 'package:flutter/material.dart';

abstract final class CakeStyle {
  static const cream = Color(0xFFFFF7E5),
      ink = Color(0xFF42251D),
      caramel = Color(0xFFB95C20),
      blush = Color(0xFFFFDCD0),
      muted = Color(0xFF88766A),
      paper = Color(0xFFFFFEFA);
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: caramel,
      primary: caramel,
      surface: paper,
      onSurface: ink,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontSize: 15, color: ink),
      bodyMedium: TextStyle(fontSize: 13, color: ink),
      bodySmall: TextStyle(fontSize: 11, color: muted),
      titleLarge: TextStyle(fontSize: 20, color: ink),
      titleMedium: TextStyle(fontSize: 15, color: ink),
      titleSmall: TextStyle(fontSize: 13, color: ink),
      labelLarge: TextStyle(fontSize: 13, color: ink),
      labelMedium: TextStyle(fontSize: 11, color: ink),
      headlineMedium: TextStyle(
        fontFamily: 'serif',
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: ink,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'serif',
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: ink,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: blush),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: blush),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
    ),
  );
}
