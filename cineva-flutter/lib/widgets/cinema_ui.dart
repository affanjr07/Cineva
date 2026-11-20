import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Compact Cineva lockup used in headers, auth screens, and empty states.
class CinevaWordmark extends StatelessWidget {
  const CinevaWordmark({
    super.key,
    this.compact = false,
    this.tagline = 'MOVIES & SERIES',
    this.onTap,
  });

  final bool compact;
  final String? tagline;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final markSize = compact ? 34.0 : 44.0;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: markSize,
          height: markSize,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 10 : 13),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Image.asset(
            'assets/logo_cineva.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
          ),
        ),
        SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CINEVA',
              style: (compact ? AppType.title : AppType.h2).copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: compact ? 2.6 : 4.2,
              ),
            ),
            if (tagline != null)
              Text(
                tagline!,
                style: AppType.caption.copyWith(
                  fontSize: compact ? 8 : 9,
                  letterSpacing: compact ? 1.6 : 2.2,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ],
    );

    if (onTap == null) return content;
    return Semantics(
      button: true,
      label: 'Cineva home',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: content,
      ),
    );
  }
}

/// Large page title with an optional eyebrow and supporting copy.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Text(
              eyebrow!.toUpperCase(),
              style: AppType.caption.copyWith(color: AppColors.primarySoft),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Text(title, style: AppType.h1)),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.md),
                trailing!,
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              style: AppType.body.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Section heading used between lists and content groups.
class CinematicSectionHeader extends StatelessWidget {
  const CinematicSectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.trailing,
    this.accent = AppColors.primary,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;
  final Color accent;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3,
            height: eyebrow == null ? 20 : 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [accent, accent.withValues(alpha: 0.35)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null)
                  Text(
                    eyebrow!.toUpperCase(),
                    style: AppType.caption.copyWith(
                      color: accent,
                      fontSize: 9.5,
                    ),
                  ),
                Text(title, style: AppType.h3),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary
                  : AppColors.surfaceLight.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.24),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 15,
                    color: selected ? AppColors.text : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 7),
                ],
                Text(
                  label,
                  style: AppType.bodySmall.copyWith(
                    color: selected ? AppColors.text : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CinemaIconButton extends StatelessWidget {
  const CinemaIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.size = 46,
    this.iconSize = 21,
    this.filled = true,
    this.foreground,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final bool filled;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: filled ? const Color(0x99050B14) : Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Container(
              width: size < 48 ? 48 : size,
              height: size < 48 ? 48 : size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: filled
                    ? Border.all(color: Colors.white.withValues(alpha: 0.11))
                    : null,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: iconSize,
                color: foreground ?? AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TypeBadge extends StatelessWidget {
  const TypeBadge({
    super.key,
    required this.label,
    this.color = AppColors.primary,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppType.caption.copyWith(
          color: color == AppColors.primary ? AppColors.primarySoft : color,
          fontSize: 9,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// Consistent fallback for a missing poster.
class PosterFallback extends StatelessWidget {
  const PosterFallback({super.key, this.iconSize = 26});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceHigh, AppColors.surface],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.movie_filter_rounded,
          size: iconSize,
          color: AppColors.textMuted,
        ),
      ),
    );
  }
}
