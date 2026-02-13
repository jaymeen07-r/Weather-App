import 'package:flutter/material.dart';

class AppThemes {
  // -------- LIGHT THEME --------
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFF009FFD), // sky blue
    primaryColor: const Color(0xFF0B132B),

    cardColor: Colors.white.withOpacity(0.25),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E3C72),
      foregroundColor: Colors.white,
    ),
  );

  // -------- DARK THEME --------
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0B132B), // deep navy

    cardColor: const Color(0xFF1C2541), // dark cards

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1C2541),
      foregroundColor: Colors.white,
    ),
  );
}
