import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/app_theme.dart';
import 'cinema_ui.dart';
import 'movie_card.dart';

const _rowSize = 8;

class MovieRow extends StatefulWidget {
  const MovieRow({
    super.key,
    required this.title,
    required this.data,
    this.topGap = AppSpacing.section,
    this.eyebrow,
  });

  final String title;
  final List<Movie> data;
  final double topGap;
  final String? eyebrow;

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

    return Padding(
      padding: EdgeInsets.only(top: widget.topGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CinematicSectionHeader(
            title: widget.title,
            eyebrow: widget.eyebrow,
            trailing: widget.data.length > 1
                ? Text('${widget.data.length} TITLES', style: AppType.caption)
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 236,
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
                    padding: const EdgeInsets.only(
                      left: AppSpacing.xs,
                      right: AppSpacing.md,
                    ),
                    child: Center(
                      child: Semantics(
                        button: true,
                        label: 'Show more ${widget.title}',
                        child: Material(
                          color: AppColors.surfaceLight,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () =>
                                setState(() => _visibleCount += _rowSize),
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.primarySoft,
                                size: 20,
                              ),
                            ),
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
