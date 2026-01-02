import 'package:flutter/material.dart';

class AppTheme {
  // MAIN COLOR PALETTE
  static const Color primary = Color(0xFF3474F6);
  static const Color bgLight = Color(0xFFEFF1F5);
  static const Color textDark = Colors.black;
  static const Color textLight = Colors.white;

  // BORDER COLOR
  static final Color borderColor = Colors.grey.shade300;

  // --------------------- LIGHT THEME ---------------------
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: bgLight,
    primaryColor: primary,

    // FIX APPBAR VISIBILITY
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 1,
      foregroundColor: textDark,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: textDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // GLOBAL TEXT
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textDark),
      displayMedium: TextStyle(color: textDark),
      displaySmall: TextStyle(color: textDark),

      headlineLarge: TextStyle(color: textDark),
      headlineMedium: TextStyle(color: textDark),
      headlineSmall: TextStyle(color: textDark),

      titleLarge: TextStyle(color: textDark, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: textDark, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: textDark),

      bodyLarge: TextStyle(color: textDark),
      bodyMedium: TextStyle(color: textDark),
      bodySmall: TextStyle(color: textDark),

      labelLarge: TextStyle(color: textDark),
      labelMedium: TextStyle(color: textDark),
      labelSmall: TextStyle(color: textDark),
    ),

    // BUTTONS
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: textLight,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: borderColor),
        foregroundColor: textDark,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),

    // TEXTFIELDS
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(16),
      hintStyle: TextStyle(color: Colors.grey.shade500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),
  );

  // --------------------- DARK THEME ---------------------
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: const Color(0xFF0E0E11),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textLight),
      bodyMedium: TextStyle(color: textLight),
      titleLarge: TextStyle(color: textLight),
      titleMedium: TextStyle(color: textLight),
      labelLarge: TextStyle(color: textLight),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A1E),
      elevation: 0,
      foregroundColor: textLight,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: textLight,
      ),
    ),
  );
}
