import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ==========================================
  // 1. COLORS
  // ==========================================
  // Backgrounds - Deep OLED black and rich charcoal
  static const Color background = Color(0xFF09090B); 
  static const Color surfaceBase = Color(0xFF141417);
  static const Color surfaceElevated = Color(0xFF1C1C22);
  static const Color surfaceHighlight = Color(0xFF27272F);

  // Primary - Vibrant neon coral/peach for high contrast
  static const Color primary = Color(0xFFFF7A59);
  static const Color primaryLight = Color(0xFFFFB399);
  static const Color primaryDark = Color(0xFFCC5A3D);

  // Secondary - Warm taupe, muted brown
  static const Color secondary = Color(0xFF947D72);
  static const Color secondaryLight = Color(0xFFC4B1A8);

  // Text
  static const Color textPrimary = Color(0xFFFAFAFA);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textDisabled = Color(0xFF52525B);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // AI / Premium Accent - Warm, glowing skin tones
  static const Color aiAccent = Color(0xFFE8B6A1); // Soft peach
  static const Color aiAccentLight = Color(0xFFFDECE4); // Very light skin tone

  // Gradients
  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFFE8B6A1), Color(0xFFD48B71), Color(0xFFFF7A59)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ==========================================
  // 2. SPACING SYSTEM
  // ==========================================
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // ==========================================
  // 3. BORDER RADIUS
  // ==========================================
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;
  static const double radiusPill = 999.0;

  static BorderRadius get borderRadiusSmall => BorderRadius.circular(radiusSmall);
  static BorderRadius get borderRadiusMedium => BorderRadius.circular(radiusMedium);
  static BorderRadius get borderRadiusLarge => BorderRadius.circular(radiusLarge);
  static BorderRadius get borderRadiusXLarge => BorderRadius.circular(radiusXLarge);
  static BorderRadius get borderRadiusPill => BorderRadius.circular(radiusPill);

  // ==========================================
  // 4. THEME DATA
  // ==========================================
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        surface: surfaceBase,
        onSurface: textPrimary,
        error: error,
        onError: Colors.white,
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: const TextStyle(color: textPrimary, fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -1.0),
        displayMedium: const TextStyle(color: textPrimary, fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        displaySmall: const TextStyle(color: textPrimary, fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.25),
        headlineLarge: const TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w600),
        headlineMedium: const TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: const TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleMedium: const TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
        bodyMedium: const TextStyle(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w400, height: 1.5),
        bodySmall: const TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w400, height: 1.4),
        labelLarge: const TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5), // Button text
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceElevated,
        elevation: 0,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: borderRadiusPill),
          padding: const EdgeInsets.symmetric(vertical: space16, horizontal: space24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Outfit'),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: surfaceHighlight, width: 1.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: borderRadiusPill),
          padding: const EdgeInsets.symmetric(vertical: space16, horizontal: space24),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Outfit'),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Outfit'),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03), // Glassy fill
        contentPadding: const EdgeInsets.symmetric(vertical: space16, horizontal: space20),
        border: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1), // Slight matching border
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1), // Very subtle glassy focus highlight
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1), // Slight matching border, no red
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadiusMedium,
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1), // Same as focused
        ),
        prefixIconColor: textSecondary, // Prevents icons from turning red
        suffixIconColor: textSecondary, // Prevents eye icon from turning red
        hintStyle: const TextStyle(color: textDisabled, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: surfaceElevated,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusLarge,
          side: const BorderSide(color: surfaceHighlight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shadowColor: Colors.black.withValues(alpha: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusLarge,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        titleTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Outfit',
        ),
        contentTextStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontFamily: 'Outfit',
          height: 1.5,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLarge)),
          side: BorderSide(color: surfaceHighlight, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: const TextStyle(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Outfit',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: borderRadiusMedium,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 12,
      ),
      switchTheme: SwitchThemeData(
        splashRadius: 0.0,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
      dividerTheme: const DividerThemeData(
        color: surfaceHighlight,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // To prevent breaking existing references, map lightTheme to darkTheme for now
  // Fallback for lightTheme usage
  static ThemeData get lightTheme => darkTheme;

  // Aliases for old properties to avoid breaking the rest of the app immediately before we fix them
  static const Color backgroundDark = background; 
  static const Color surfaceColor = surfaceBase;
  static const Color primaryColor = primary;
  static const Color secondaryColor = secondary;
  static const Color errorColor = error;
  static const Color successColor = success;
}
