import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Deep, High-Contrast Dark Theme Palette
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color cardBg = Color(0xFF1E293B); // Slate 800
  static const Color cardBgElevated = Color(0xFF334155); // Slate 700
  static const Color cardBorder = Color(0xFF475569); // Slate 600
  
  // Vibrant Accents for good contrast against dark backgrounds
  static const Color primaryAccent = Color(0xFF38BDF8); // Light Blue
  static const Color brightAccent = Color(0xFF7DD3FC);
  
  static const Color cyanAccent = Color(0xFF22D3EE);
  static const Color dangerRed = Color(0xFFF43F5E);
  static const Color brightDangerRed = Color(0xFFFB7185);
  static const Color successGreen = Color(0xFF10B981); // Emerald 500
  static const Color textMain = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400

  // Typography Styles (Sans-serif)
  static TextStyle monoHeader({double fontSize = 18, Color color = textMain, FontWeight weight = FontWeight.w600}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      color: color,
      fontWeight: weight,
      letterSpacing: -0.5,
    );
  }

  static TextStyle monoSubheader({double fontSize = 12, Color color = primaryAccent, FontWeight weight = FontWeight.w500}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      color: color,
      fontWeight: weight,
      letterSpacing: 0.5,
    );
  }

  static TextStyle monoValue({double fontSize = 28, Color color = textMain, FontWeight weight = FontWeight.bold}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      color: color,
      fontWeight: weight,
      letterSpacing: -1.0,
    );
  }

  static TextStyle bodyText({double fontSize = 14, Color color = textSecondary, FontWeight weight = FontWeight.normal}) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      color: color,
      fontWeight: weight,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryAccent,
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        secondary: brightAccent,
        surface: cardBg,
        error: dangerRed,
        onPrimary: Colors.white,
        onSurface: textMain,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: textMain),
        titleTextStyle: monoHeader(fontSize: 18, color: textMain, weight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardBg,
        selectedItemColor: primaryAccent,
        unselectedItemColor: textSecondary,
        selectedLabelStyle: monoSubheader(fontSize: 11, color: primaryAccent),
        unselectedLabelStyle: monoSubheader(fontSize: 11, color: textSecondary),
        elevation: 10,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
    );
  }
}
