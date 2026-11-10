import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Sribees Typography Hierarchy
/// Uses 'Outfit' for modern titles/headings and 'Inter' for clean readable body/prices.
class AppTypography {
  AppTypography._();

  // Headings (Outfit)
  static TextStyle h1({Color color = AppColors.ink}) => GoogleFonts.outfit(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle h2({Color color = AppColors.ink}) => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
      );

  static TextStyle h3({Color color = AppColors.ink}) => GoogleFonts.outfit(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // Price Display Typography (Outfit Bold)
  static TextStyle priceBig({Color color = AppColors.primary}) => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle priceCard({Color color = AppColors.primary}) => GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle priceBaseOld({Color color = AppColors.muted}) => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
        decoration: TextDecoration.lineThrough,
      );

  // Body Text (Inter)
  static TextStyle bodyLarge({Color color = AppColors.ink}) => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle bodyMedium({Color color = AppColors.inkSecondary}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodySmall({Color color = AppColors.muted}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle button({Color color = Colors.white}) => GoogleFonts.outfit(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.2,
      );

  static TextStyle badge({Color color = AppColors.primaryDark}) => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      );
}
