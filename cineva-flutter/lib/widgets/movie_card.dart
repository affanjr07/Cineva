import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/series_detail_screen.dart';
import '../theme/app_theme.dart';
import '../utils/routes.dart';
import 'cinema_ui.dart';

class MovieCard extends StatefulWidget {
  const MovieCard({
    super.key,
    required this.movie,
    this.width,
    this.showTitle = true,
  });

  final Movie movie;
  final double? width;
  final bool showTitle;

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  double _scale = 1;

  double _posterWidth() {
    if (widget.width != null) return widget.width!;
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth - AppSpacing.lg * 2 - AppSpacing.md * 2) / 3;
  }

  void _open() {
    final movie = widget.movie;
    if (movie.type == 'series') {
      Navigator.of(context).push(
        cinevaPageRoute(
          SeriesDetailScreen(id: movie.id, poster: movie.posterImg),
        ),
      );
    } else {
      Navigator.of(context).push(
        cinevaPageRoute(
          MovieDetailScreen(id: movie.id, poster: movie.posterImg),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final cardWidth = _posterWidth();
    final hasMargin = widget.width == null;

    return Semantics(
      button: true,
      label:
          '${movie.title}. ${movie.type}.${movie.rating.isNotEmpty ? ' Rating ${movie.rating}.' : ''}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.96),
        onTapUp: (_) => setState(() => _scale = 1),
        onTapCancel: () => setState(() => _scale = 1),
        onTap: _open,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: Container(
            width: cardWidth,
            margin: EdgeInsets.only(right: hasMargin ? AppSpacing.md : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: movie.posterImg,
                          fit: BoxFit.cover,
                          placeholder: (_, _) =>
                              const PosterFallback(iconSize: 22),
                          errorWidget: (_, _, _) =>
                              const PosterFallback(iconSize: 22),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppGradients.posterScrim,
                          ),
                        ),
                        Positioned(
                          top: AppSpacing.sm,
                          left: AppSpacing.sm,
                          right: AppSpacing.sm,
                          child: Row(
                            children: [
                              if (movie.qualityResolution.isNotEmpty)
                                _PosterTag(
                                  label: movie.qualityResolution,
                                  emphasized: true,
                                ),
                              const Spacer(),
                              if (movie.type == 'series')
                                const _PosterTag(
                                  label: 'SERIES',
                                  color: AppColors.secondary,
                                ),
                            ],
                          ),
                        ),
                        if (movie.rating.isNotEmpty)
                          Positioned(
                            left: AppSpacing.sm,
                            right: AppSpacing.sm,
                            bottom: AppSpacing.sm,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: AppColors.rating,
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  movie.rating,
                                  style: AppType.caption.copyWith(
                                    color: AppColors.text,
                                    fontSize: 10,
                                    letterSpacing: 0.2,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (widget.showTitle) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    movie.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.body.copyWith(
                      color: AppColors.text,
                      fontSize: 12.5,
                      height: 1.28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PosterTag extends StatelessWidget {
  const _PosterTag({required this.label, this.emphasized = false, this.color});

  final String label;
  final bool emphasized;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tagColor = emphasized ? AppColors.primary : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: tagColor?.withValues(alpha: 0.88) ?? const Color(0x99050B14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color:
              tagColor?.withValues(alpha: 0.34) ??
              Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppType.caption.copyWith(
          color: AppColors.text,
          fontSize: 8,
          letterSpacing: 0.6,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
