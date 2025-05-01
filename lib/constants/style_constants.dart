
// constants/style_constants.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary Mentimeter colors
  static const Color primaryBlue = Color(0xFF5769E7);
  static const Color errorRed = Color(0xFFFF7471);
  static const Color backgroundLightBlue = Color(0xFFD5DAF7);
  static const Color backgroundLightRed = Color(0xFFFFDEDD);
  
  // Additional colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color textDark = Color(0xFF333333);
  static const Color textLight = Color(0xFF666666);
  static const Color dividerColor = Color(0xFFEEEEEE);
  
  // Avatar colors for players
  static final List<Color> avatarColors = [
    primaryBlue,
    errorRed,
    Color(0xFF46BFBD), // teal
    Color(0xFFFDB45C), // amber
    Color(0xFF949FB1), // blue-grey
    Color(0xFF4D5360), // dark grey
    Color(0xFF97BBCD), // light blue
    Color(0xFFDCDCDC), // light grey
  ];
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.errorRed,
        error: AppColors.errorRed,
        background: AppColors.backgroundLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.primaryBlue),
        titleTextStyle: TextStyle(
          color: AppColors.primaryBlue,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.errorRed),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: AppColors.textDark),
        bodyMedium: TextStyle(color: AppColors.textDark),
      ),
    );
  }
}