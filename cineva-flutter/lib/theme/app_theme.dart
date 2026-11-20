import 'package:flutter/material.dart';

/// Cineva's OLED-first palette. Deep navy surfaces keep posters and video
/// content dominant, while blue is reserved for primary actions and active
/// navigation. Violet marks AI and series content, amber carries ratings, and
/// emerald is reserved for success/status.
class AppColors {
  AppColors._();

  static const background = Color(0xFF050B14);
  static const backgroundSoft = Color(0xFF070F1C);
  static const surface = Color(0xFF0B1220);
  static const surfaceLight = Color(0xFF111827);
  static const surfaceHigh = Color(0xFF1B263B);
  static const primary = Color(0xFF2563EB);
  static const primaryMuted = Color(0xFF3B82F6);
  static const primarySoft = Color(0xFF60A5FA);
  static const primaryDeep = Color(0xFF1E3A8A);
  static const secondary = Color(0xFF7C3AED);
  static const secondarySoft = Color(0xFFC4B5FD);
  static const secondaryDeep = Color(0xFF4C1D95);
  static const text = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF93A4BC);
  static const textMuted = Color(0xFF7B8AA0);
  static const border = Color(0xFF1E293B);
  static const borderLight = Color(0xFF334155);
  static const accent = primary;
  static const card = Color(0xFF0B1220);
  static const cardLight = Color(0xFF111827);
  static const rating = Color(0xFFFBBF24);
  static const success = Color(0xFF34D399);
  static const error = Color(0xFFFB7185);
  static const overlay = Color(0xCC050B14);
  static const transparent = Color(0x00000000);
}

class AppGradients {
  AppGradients._();

  static const heroScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x99000000),
      Color(0x26000000),
      Color(0xCC050B14),
      AppColors.background,
    ],
    stops: [0, 0.34, 0.78, 1],
  );

  static const posterScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.transparent, Color(0xB3050B14)],
    stops: [0.52, 1],
  );

  static const accent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primaryDeep],
  );

  static const accentGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.secondary],
  );

  static const ai = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.secondary, AppColors.secondaryDeep],
  );
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
  static const double huge = 48;
  static const double section = 40;
}

class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 28;
  static const double pill = 999;
}

class AppType {
  AppType._();

  static const _family = 'Inter';

  static const display = TextStyle(
    fontFamily: _family,
    fontSize: 40,
    height: 1.05,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
    letterSpacing: -1.2,
  );
  static const h1 = TextStyle(
    fontFamily: _family,
    fontSize: 32,
    height: 1.1,
    fontWeight: FontWeight.w800,
    color: AppColors.text,
    letterSpacing: -0.9,
  );
  static const h2 = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    height: 1.18,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    letterSpacing: -0.4,
  );
  static const h3 = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    letterSpacing: -0.2,
  );
  static const title = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    letterSpacing: -0.1,
  );
  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    height: 1.55,
    fontWeight: FontWeight.w400,
    color: Color(0xFFD6DFEC),
  );
  static const bodySmall = TextStyle(
    fontFamily: _family,
    fontSize: 12.5,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const caption = TextStyle(
    fontFamily: _family,
    fontSize: 10.5,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 1.4,
  );
  static const label = TextStyle(
    fontFamily: _family,
    fontSize: 11.5,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 1.2,
  );
  static const button = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    letterSpacing: 0.1,
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final textTheme = base.textTheme
      .apply(
        fontFamily: 'Inter',
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      )
      .copyWith(
        displayLarge: AppType.display,
        displayMedium: AppType.h1,
        displaySmall: AppType.h2,
        headlineLarge: AppType.h1,
        headlineMedium: AppType.h2,
        headlineSmall: AppType.h3,
        titleLarge: AppType.title,
        titleMedium: AppType.title,
        titleSmall: AppType.body,
        bodyLarge: AppType.body,
        bodyMedium: AppType.body,
        bodySmall: AppType.bodySmall,
        labelLarge: AppType.button,
        labelMedium: AppType.label,
        labelSmall: AppType.caption,
      );

  const colorScheme = ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: AppColors.text,
    primaryContainer: Color(0xFF172554),
    onPrimaryContainer: AppColors.primarySoft,
    secondary: AppColors.secondary,
    onSecondary: AppColors.text,
    secondaryContainer: Color(0xFF2E1065),
    onSecondaryContainer: AppColors.secondarySoft,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.error,
    onError: AppColors.background,
    outline: AppColors.border,
    outlineVariant: AppColors.borderLight,
  );

  return base.copyWith(
    colorScheme: colorScheme,
    canvasColor: AppColors.background,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    iconTheme: const IconThemeData(color: AppColors.text, size: 22),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    splashFactory: InkRipple.splashFactory,
    visualDensity: VisualDensity.standard,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primarySoft,
      selectionColor: Color(0x663B82F6),
      selectionHandleColor: AppColors.primary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.text),
      titleTextStyle: AppType.h3,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      modalBackgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: AppColors.borderLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.xl)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: AppType.body.copyWith(color: AppColors.text),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      hintStyle: AppType.body.copyWith(color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: const BorderSide(color: AppColors.error, width: 1.4),
      ),
      errorStyle: AppType.bodySmall.copyWith(color: AppColors.error),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.text,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
        disabledForegroundColor: AppColors.text.withValues(alpha: 0.55),
        minimumSize: const Size(48, 52),
        textStyle: AppType.button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        minimumSize: const Size(48, 50),
        textStyle: AppType.button,
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primarySoft,
        minimumSize: const Size(48, 44),
        textStyle: AppType.button,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.surfaceHigh,
      circularTrackColor: AppColors.surfaceHigh,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.text,
      unselectedLabelColor: AppColors.textMuted,
      indicatorColor: AppColors.primary,
    ),
  );
}
