import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Clean, High-Contrast Flat Design Colors (Spotify/Netflix Style)
  static const Color backgroundDark = Color(0xFF121212); // Deep Spotify black
  static const Color surfaceColor = Color(0xFF1E1E1E); // Elevated dark gray

  // Premium Organic Skin-Tone Palette (Fair, Medium, Deep)
  static const Color primaryColor = Color(0xFFC68B74); // Warm Caramel / Medium
  static const Color primaryLight = Color(0xFFF1D1C3); // Soft Peach / Fair
  static const Color secondaryColor = Color(0xFF5D3A29); // Deep Cocoa / Deep
  static const Color errorColor = Color(0xFFD9534F); // Muted Coral Red
  static const Color successColor = Color(0xFF81B29A); // Soft Sage Green

  // Text Colors
  static const Color textPrimary = Color(0xFFFFF6F3); // Warm Off-White
  static const Color textSecondary = Color(0xFFBCAAA4); // Soft Taupe

  // Gradients for UI
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFFE5B5A1),
      Color(0xFFC68B74),
      Color(0xFF8A5A44),
    ], // Fair to Deep
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtleGlassGradient = LinearGradient(
    colors: [Color(0x1AFFFFFF), Color(0x05FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            displayMedium: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            headlineLarge: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
            bodyLarge: const TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
            bodyMedium: const TextStyle(
              color: textSecondary,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.2,
            ),
          ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          elevation: 0, // No shadow
          animationDuration: const Duration(milliseconds: 180),
          overlayColor: primaryLight.withValues(alpha: 0.18),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryColor,
          side: const BorderSide(color: secondaryColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
          animationDuration: const Duration(milliseconds: 180),
          overlayColor: primaryColor.withValues(alpha: 0.14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          animationDuration: const Duration(milliseconds: 180),
          overlayColor: primaryColor.withValues(alpha: 0.14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor.withValues(alpha: 0.5), // Glassy fill
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 24,
        ),
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
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(surfaceColor),
        ),
      ),
      canvasColor: surfaceColor,
      cardTheme: CardThemeData(
        color: surfaceColor.withValues(alpha: 0.7),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ), // Subtle rim light
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
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
