import 'package:flutter/material.dart';

/// Sribees Official Brand Color Tokens & Theme Palettes
class AppColors {
  AppColors._();

  // Sribees Primary Brand Colors
  static const Color primary = Color(0xFFD81B60);       // Sribees Signature Crimson Pink
  static const Color primaryLight = Color(0xFFE0457E);  // Soft Tint Magenta
  static const Color primaryDark = Color(0xFFB01550);   // Deep Crimson
  static const Color primaryTint = Color(0xFFFBE3EC);   // Very light pink for chips & highlights

  // Secondary & Accents
  static const Color amber = Color(0xFFFFB300);         // Sribees Warm Gold / Star
  static const Color amberDark = Color(0xFFE69900);
  static const Color amberLight = Color(0xFFFFF3D6);

  // Volatility Level Color Coding (Information Architecture)
  static const Color level1Daily = Color(0xFF1F7A32);    // Emerald Green - Daily Fresh
  static const Color level1Bg = Color(0xFFE8F5E9);
  static const Color level2Weekly = Color(0xFFD97706);   // Warm Amber - Weekly Staples
  static const Color level2Bg = Color(0xFFFEF3C7);
  static const Color level3Monthly = Color(0xFF2563EB);  // Royal Blue - FMCG / Packaged
  static const Color level3Bg = Color(0xFFEFF6FF);
  static const Color level4Rare = Color(0xFF6B7280);     // Cool Grey - Long Shelf Life
  static const Color level4Bg = Color(0xFFF3F4F6);

  // Neutral Colors (Light Theme)
  static const Color bgLight = Color(0xFFF8F9FB);       // Clean canvas grey
  static const Color surfaceLight = Color(0xFFFFFFFF);  // Pure white card background
  static const Color ink = Color(0xFF1A1A22);           // Primary text (near black)
  static const Color inkSecondary = Color(0xFF4A4A58);  // Secondary body text
  static const Color muted = Color(0xFF8C8C97);         // Captions, SKU, subtitles
  static const Color border = Color(0xFFE8E7EC);        // Card & divider border
  static const Color borderLight = Color(0xFFF2F2F6);

  // Status & Feedback
  static const Color success = Color(0xFF1F7A32);
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color error = Color(0xFFE53935);
  static const Color errorBg = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color info = Color(0xFF0288D1);
  static const Color infoBg = Color(0xFFE1F5FE);

  // Neutral Colors (Dark Theme)
  static const Color bgDark = Color(0xFF101015);
  static const Color surfaceDark = Color(0xFF1B1B22);
  static const Color cardDark = Color(0xFF23232C);
  static const Color borderDark = Color(0xFF2D2D38);
  static const Color inkDark = Color(0xFFF5F5F7);
}
