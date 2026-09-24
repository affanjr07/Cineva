import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:cineva_flutter/theme/app_theme.dart';

void main() {
  test('Theme colors match the Cineva dark theme', () {
    expect(AppColors.background, const Color(0xFF050B14));
    expect(AppColors.surface, const Color(0xFF0B1220));
    expect(AppColors.primary, const Color(0xFF2563EB));
  });

  test('AppTheme builds without errors', () {
    final theme = buildAppTheme();
    expect(theme.scaffoldBackgroundColor, AppColors.background);
  });
}