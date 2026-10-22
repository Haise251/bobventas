import 'package:flutter/material.dart';

/// Tema visual de la app (idéntico al original: oscuro con acento naranja).
class AppTheme {
  AppTheme._();

  static const Color accent = Color(0xFFFF7043);
  static const Color accentSoft = Color(0xFFFFD700);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color background = Color(0xFF121212);
  static const Color cardDark = Color(0xFF121212);

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
        primary: accent,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: accent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: accent.withOpacity(0.2)),
        ),
      ),
    );
  }
}
