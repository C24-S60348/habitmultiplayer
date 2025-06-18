import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FYTheme {
  // Primary colors
  static const Color primaryOrange = Color(0xFFE67F3E);
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color primaryWhite = Color(0xFFFFFFFF);
  
  // Secondary colors
  static const Color secondaryGray = Color(0xFF6B7280);
  static const Color secondaryLightGray = Color(0xFFF3F4F6);
  static const Color secondaryDarkGray = Color(0xFF374151);
  
  // Background colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF1F2937);
  
  // Text colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight = Color(0xFFFFFFFF);
  
  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Theme data
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.orange,
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryOrange,
        foregroundColor: primaryWhite,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryWhite,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: primaryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.15,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.orange,
      primaryColor: primaryOrange,
      scaffoldBackgroundColor: backgroundDark,
      fontFamily: GoogleFonts.inter().fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: primaryWhite,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: primaryWhite,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: primaryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.inter(
          color: primaryWhite,
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.inter(
          color: primaryWhite,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
        ),
        bodyLarge: GoogleFonts.inter(
          color: primaryWhite,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.15,
        ),
        bodyMedium: GoogleFonts.inter(
          color: secondaryGray,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
      ),
    );
  }
}
