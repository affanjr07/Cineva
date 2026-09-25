import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/series_detail_screen.dart';
import '../theme/app_theme.dart';
import '../utils/routes.dart';

class MovieCard extends StatefulWidget {
  const MovieCard({super.key, required this.movie, this.width});

  final Movie movie;
  final double? width;

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  double _scale = 1.0;

  double _posterWidth() {
    if (widget.width != null) return widget.width!;
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth - AppSpacing.lg * 2 - AppSpacing.md * 2) / 3;
  }

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final cardWidth = _posterWidth();
    final noRightMargin = widget.width != null;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {
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
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: cardWidth,
          margin: EdgeInsets.only(
            right: noRightMargin ? 0 : AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Hero(
                    tag: 'poster-${movie.id}',
                    child: Container(
                      width: cardWidth,
                      height: cardWidth * 1.5,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        color: AppColors.surfaceLight,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                        imageUrl: movie.posterImg,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Center(
                          child: Text('🎬',
                              style: TextStyle(fontSize: 24)),
                        ),
                      ),
                    ),
                  ),
                  if (movie.qualityResolution.isNotEmpty)
                    Positioned(
                      top: AppSpacing.xs,
                      left: AppSpacing.xs,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs + 2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          movie.qualityResolution,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '⭐ ${movie.rating}',
                style: const TextStyle(
                  color: AppColors.rating,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}