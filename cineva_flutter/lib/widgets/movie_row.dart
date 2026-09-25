import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'movie_card.dart';

const _rowSize = 8;

class MovieRow extends StatefulWidget {
  const MovieRow({super.key, required this.title, required this.data});

  final String title;
  final List<Movie> data;

  @override
  State<MovieRow> createState() => _MovieRowState();
}

class _MovieRowState extends State<MovieRow> {
  int _visibleCount = _rowSize;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox.shrink();
    final visible = widget.data.take(_visibleCount).toList();
    final hasMore = _visibleCount < widget.data.length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              bottom: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(widget.title, style: AppType.h3),
              ],
            ),
          ),
          SizedBox(
            height: 260,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.md,
              ),
              children: [
                ...visible.map((m) => MovieCard(movie: m)),
                if (hasMore)
                  Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.sm,
                      right: AppSpacing.md,
                    ),
                    child: Center(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _visibleCount += _rowSize),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceLight,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: AppColors.text,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}