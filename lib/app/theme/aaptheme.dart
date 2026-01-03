import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,

    // 🔹 Use your custom font families
    fontFamily: "OpenSans Regular",

    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        fontFamily: "OpenSans Regular",
        fontSize: 18,
      ),
      bodyMedium: TextStyle(
        fontFamily: "OpenSans Regular",
        fontSize: 16,
      ),
      bodySmall: TextStyle(
        fontFamily: "OpenSans Regular",
        fontSize: 14,
      ),
      titleLarge: TextStyle(
        fontFamily: "OpenSans Bold",
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
      titleMedium: TextStyle(
        fontFamily: "OpenSans Bold",
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      titleSmall: TextStyle(
        fontFamily: "OpenSans Bold",
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
