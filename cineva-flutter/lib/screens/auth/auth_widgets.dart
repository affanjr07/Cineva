import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/cinema_ui.dart';

/// Quiet, cinematic shell shared by every authentication screen.
///
/// The auth flow deliberately avoids large glows and decorative badges. A
/// single vertical gradient, generous spacing, and one accent color keep the
/// focus on the form.
class AuthPageShell extends StatelessWidget {
  const AuthPageShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF081321),
              AppColors.background,
              Color(0xFF03070E),
            ],
            stops: [0, 0.58, 1],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0, constraints.maxHeight - 40),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 48,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const CinevaWordmark(
                                  compact: true,
                                  tagline: null,
                                ),
                                if (canPop)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: CinemaIconButton(
                                      icon: Icons.arrow_back_rounded,
                                      tooltip: 'Back',
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      size: 40,
                                      iconSize: 20,
                                      filled: false,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.huge + 4),
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
  });

  final String title;
  final String subtitle;
  final String? eyebrow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            style: AppType.caption.copyWith(
              color: AppColors.primarySoft,
              fontSize: 10,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md + 2),
        ],
        Text(
          title,
          style: AppType.h1.copyWith(
            fontSize: 34,
            letterSpacing: -1.1,
            height: 1.06,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          subtitle,
          style: AppType.body.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppType.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          textField: true,
          label: label,
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            validator: validator,
            obscureText: obscureText,
            onFieldSubmitted: onFieldSubmitted,
            autocorrect: false,
            enableSuggestions: !obscureText,
            style: AppType.body.copyWith(color: AppColors.text),
            cursorColor: AppColors.primarySoft,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppType.bodySmall.copyWith(color: AppColors.textMuted),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: AppColors.surfaceLight.withValues(alpha: 0.82),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 17,
              ),
              border: _border(AppColors.border),
              enabledBorder: _border(AppColors.border),
              focusedBorder: _border(AppColors.primary, width: 1.4),
              errorBorder: _border(AppColors.error),
              focusedErrorBorder: _border(AppColors.error, width: 1.3),
              errorStyle: AppType.bodySmall.copyWith(
                color: AppColors.error,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.text,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.text,
                  ),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: AppType.button.copyWith(fontSize: 15)),
                    const SizedBox(width: AppSpacing.sm + 2),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.22)),
        ),
        child: Text(
          message,
          style: AppType.bodySmall.copyWith(
            color: AppColors.error,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}
