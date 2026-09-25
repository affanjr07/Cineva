import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RatingBadge extends StatelessWidget {
  const RatingBadge({
    super.key,
    required this.rating,
    this.medium = false,
  });

  final String rating;
  final bool medium;

  @override
  Widget build(BuildContext context) {
    final numRating = double.tryParse(rating) ?? 0;

    Color bgColor = AppColors.primary;
    if (numRating >= 7) {
      bgColor = AppColors.success;
    } else if (numRating >= 5) {
      bgColor = AppColors.rating;
    } else if (numRating < 4) {
      bgColor = AppColors.error;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: medium ? AppSpacing.md : AppSpacing.sm,
        vertical: medium ? AppSpacing.xs : 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '⭐ $rating',
        style: TextStyle(
          color: AppColors.text,
          fontSize: medium ? 12 : 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}