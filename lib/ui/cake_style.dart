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
      bodyMedium: TextStyle(color: ink),
      headlineMedium: TextStyle(
        fontFamily: 'serif',
        fontSize: 29,
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
