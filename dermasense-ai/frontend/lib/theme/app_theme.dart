import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Deep Obsidian Dark Mode Colors
  static const Color backgroundDark = Color(0xFF0A0A0E); // Deep space black
  static const Color surfaceColor = Color(0xFF161622); // Translucent dark gray for glassmorphism

  // Vibrant Neon Accents
  static const Color primaryColor = Color(0xFF6B4EE6); // Electric Violet
  static const Color primaryLight = Color(0xFF8E71FF);
  static const Color secondaryColor = Color(0xFF00F2FE); // Cyan Glow
  static const Color errorColor = Color(0xFFFF4B4B); // Neon Red
  static const Color successColor = Color(0xFF00E676); // Neon Green

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // Crisp White
  static const Color textSecondary = Color(0xFFA0A4B8); // Slate Gray

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        displayLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        displayMedium: const TextStyle(color: textPrimary, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        headlineLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
        bodyLarge: const TextStyle(color: textPrimary, fontWeight: FontWeight.w400, letterSpacing: 0.2),
        bodyMedium: const TextStyle(color: textSecondary, fontWeight: FontWeight.w400, letterSpacing: 0.2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, // Base color, but we'll use containers for real gradients
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          elevation: 10,
          shadowColor: primaryColor.withValues(alpha: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryColor,
          side: const BorderSide(color: secondaryColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor.withValues(alpha: 0.5), // Glassy fill
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1), // Subtle rim light
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor.withValues(alpha: 0.9),
        elevation: 0,
        selectedItemColor: secondaryColor,
        unselectedItemColor: textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // To prevent breaking existing references, map lightTheme to darkTheme for now
  static ThemeData get lightTheme => darkTheme;
}
