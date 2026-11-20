import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon = Icons.movie_filter_rounded,
    this.title = 'Nothing here',
    this.message = 'No content available.',
    this.actionLabel,
    this.onAction,
    this.expanded = true,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 31, color: AppColors.primarySoft),
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(title, style: AppType.h3, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            message,
            style: AppType.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.xxl),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.explore_outlined, size: 18),
            label: Text(actionLabel!),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.md,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
        ],
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxxl,
      ),
      child: expanded ? Center(child: content) : content,
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.message = 'Failed to load content.',
    this.onRetry,
  });

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxxl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.09),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.24),
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 30,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('Something went wrong', style: AppType.h3),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message ?? 'Failed to load content.',
                style: AppType.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try again'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              label!,
              style: AppType.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadius.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceHigh, AppColors.surfaceLight],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.025)),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    final cardWidth =
        width ??
        (MediaQuery.of(context).size.width -
                AppSpacing.lg * 2 -
                AppSpacing.md * 3) /
            3;
    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(
            width: cardWidth,
            height: cardWidth * 1.5,
            radius: AppRadius.lg,
          ),
          const SizedBox(height: AppSpacing.sm),
          SkeletonBox(width: cardWidth * 0.9, height: 10, radius: 4),
        ],
      ),
    );
  }
}
