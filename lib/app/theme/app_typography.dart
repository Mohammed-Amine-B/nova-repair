import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  const AppTypography._();

  static const fontFamily = 'Manrope';
  static const fallbackFonts = ['Segoe UI', 'Arial', 'sans-serif'];

  static const textTheme = TextTheme(
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 30,
      height: 38 / 30,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 24,
      height: 32 / 24,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 20,
      height: 28 / 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 13,
      height: 18 / 13,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: 11,
      height: 14 / 11,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    ),
  );
}
