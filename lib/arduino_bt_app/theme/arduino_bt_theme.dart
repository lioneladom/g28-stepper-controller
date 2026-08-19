import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArduinoBtTheme {
  // Color Palette
  static const Color bgDark = Color(0xFF0B0F19);
  static const Color cardBg = Color(0xFF161E2E);
  static const Color cardBorder = Color(0xFF232F45);

  static const Color primaryCyan = Color(0xFF00E5FF);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentOrange = Color(0xFFFF9100);
  static const Color successGreen = Color(0xFF10B981);
  static const Color dangerRed = Color(0xFFFF1744);
  static const Color warningYellow = Color(0xFFFFC107);

  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: bgDark,
      primaryColor: primaryCyan,
      colorScheme: const ColorScheme.dark(
        primary: primaryCyan,
        secondary: accentPurple,
        surface: cardBg,
        error: dangerRed,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cardBorder, width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  // Typography Styles
  static TextStyle headerStyle({double fontSize = 20, Color color = textMain, FontWeight weight = FontWeight.bold}) {
    return GoogleFonts.orbitron(
      fontSize: fontSize,
      color: color,
      fontWeight: weight,
      letterSpacing: 1.2,
    );
  }

  static TextStyle monoStyle({double fontSize = 14, Color color = textMain, FontWeight weight = FontWeight.w600}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      color: color,
      fontWeight: weight,
    );
  }

  static TextStyle bodyStyle({double fontSize = 14, Color color = textMuted, FontWeight weight = FontWeight.normal}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      color: color,
      fontWeight: weight,
    );
  }
}
