import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'auth_widgets.dart';

class AuthUnavailableScreen extends StatelessWidget {
  const AuthUnavailableScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return AuthPageShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.primarySoft,
              size: 26,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AuthHeader(
            title: 'Connect Supabase',
            subtitle:
                'Authentication is ready, but this build does not have the '
                'Supabase project keys yet.',
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            message ??
                'Add the following values to .env, then restart the app with '
                    '--dart-define-from-file=.env.',
            style: AppType.bodySmall.copyWith(height: 1.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          const _EnvRow(name: 'SUPABASE_URL'),
          const SizedBox(height: AppSpacing.sm),
          const _EnvRow(name: 'SUPABASE_PUBLISHABLE_KEY'),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Then run the SQL file in supabase/migrations/ inside the '
            'Supabase SQL Editor to create the profiles table and its RLS '
            'policies.',
            style: AppType.caption.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _EnvRow extends StatelessWidget {
  const _EnvRow({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: SelectableText(
        name,
        style: AppType.bodySmall.copyWith(
          color: AppColors.primarySoft,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
