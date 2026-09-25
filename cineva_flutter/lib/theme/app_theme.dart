import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background = Color(0xFF050B14);
  static const surface = Color(0xFF0B1220);
  static const surfaceLight = Color(0xFF111827);
  static const primary = Color(0xFF2563EB);
  static const primaryMuted = Color(0xFF3B82F6);
  static const primarySoft = Color(0xFF60A5FA);
  static const text = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF6B7280);
  static const border = Color(0xFF1F2937);
  static const borderLight = Color(0xFF374151);
  static const accent = Color(0xFF2563EB);
  static const card = Color(0xFF0B1220);
  static const cardLight = Color(0xFF1F2937);
  static const rating = Color(0xFFF59E0B);
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const overlay = Color(0xCC050B14);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

class AppRadius {
  AppRadius._();

  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
}

class AppType {
  AppType._();

  static const h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    letterSpacing: 0.5,
  );
  static const h2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    letterSpacing: 0.3,
  );
  static const h3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );
  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFFE5E7EB),
    height: 20 / 14,
  );
  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 16 / 12,
  );
  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );
  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.8,
  );
  static const button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
    letterSpacing: 0.3,
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.primaryMuted,
      selectionHandleColor: AppColors.primary,
    ),
    splashFactory: InkRipple.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.text),
      titleTextStyle: AppType.h2,
    ),
  );
}