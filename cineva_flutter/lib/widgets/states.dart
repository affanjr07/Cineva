import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.title = 'Nothing here',
    this.message = 'No content available.',
    this.actionLabel,
    this.onAction,
    this.expanded = true,
  });

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
        const Text('🎬', style: TextStyle(fontSize: 48)),
        const SizedBox(height: AppSpacing.lg),
        Text(title,
            style: AppType.h3, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.sm),
        Text(
          message,
          style: AppType.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.xxl),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: Text(actionLabel!, style: AppType.button),
              ),
            ),
          ),
        ],
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxxl * 2,
      ),
      child: expanded
          ? Center(
              child: content,
            )
          : content,
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
        vertical: AppSpacing.xxxl * 2,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 48)),
            const SizedBox(height: AppSpacing.lg),
            const Text('Something went wrong', style: AppType.h3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message ?? 'Failed to load content.',
              style: AppType.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: InkWell(
                  onTap: onRetry,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    child: Text('Try Again', style: AppType.button),
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
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.width});

  final double? width;

  @override
  Widget build(BuildContext context) {
    final cardWidth = width ??
        (MediaQuery.of(context).size.width -
                AppSpacing.lg * 2 -
                AppSpacing.md * 2) /
            3;
    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: cardWidth,
            height: cardWidth * 1.5,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: cardWidth * 0.9,
            height: 10,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}