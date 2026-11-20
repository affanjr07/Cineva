import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'cinema_ui.dart';

class GenreChip extends StatelessWidget {
  const GenreChip({super.key, required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 3,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        color: active ? AppColors.primary : AppColors.surfaceLight,
        border: Border.all(
          color: active
              ? AppColors.primarySoft.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: AppType.bodySmall.copyWith(
          color: active ? AppColors.text : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.eyebrow});

  final String title;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    return CinematicSectionHeader(
      title: title,
      eyebrow: eyebrow,
      padding: EdgeInsets.zero,
    );
  }
}
