import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.rating, this.medium = false});

  final String rating;
  final bool medium;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: medium ? AppSpacing.md : AppSpacing.sm + 1,
        vertical: medium ? AppSpacing.xs + 1 : 3,
      ),
      decoration: BoxDecoration(
        color: const Color(0xCC0B1220),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            color: AppColors.rating,
            size: medium ? 15 : 12,
          ),
          const SizedBox(width: 4),
          Text(
            rating,
            style: AppType.caption.copyWith(
              color: AppColors.text,
              fontSize: medium ? 12 : 10,
              letterSpacing: 0.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
