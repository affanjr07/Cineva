import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../screens/movie_detail_screen.dart';
import '../screens/series_detail_screen.dart';
import '../stores/watch_history_store.dart';
import '../theme/app_theme.dart';
import '../utils/routes.dart';
import 'cinema_ui.dart';

class ContinueWatchingRow extends StatelessWidget {
  const ContinueWatchingRow({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WatchHistoryStore.instance,
      builder: (context, _) {
        final items = WatchHistoryStore.instance.items;
        if (items.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CinematicSectionHeader(
                title: 'Continue watching',
                eyebrow: 'PICK UP WHERE YOU LEFT OFF',
                trailing: Text(
                  '${items.length} RECENT',
                  style: AppType.caption,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 134,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.md,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _ContinueWatchingCard(item: items[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContinueWatchingCard extends StatelessWidget {
  const _ContinueWatchingCard({required this.item});

  final WatchHistoryItem item;

  void _open(BuildContext context) {
    if (item.type == 'series') {
      Navigator.of(context).push(
        cinevaPageRoute(
          SeriesDetailScreen(id: item.id, poster: item.posterImg),
        ),
      );
    } else {
      Navigator.of(context).push(
        cinevaPageRoute(MovieDetailScreen(id: item.id, poster: item.posterImg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSeries = item.type == 'series';
    final seasonLabel = isSeries && item.season > 0
        ? 'S${item.season} E${item.episode}'
        : null;

    return Semantics(
      button: true,
      label: 'Continue ${item.title}',
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: AppColors.surface,
          child: InkWell(
            onTap: () => _open(context),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (item.posterImg.isEmpty)
                  const PosterFallback(iconSize: 26)
                else
                  CachedNetworkImage(
                    imageUrl: item.posterImg,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const PosterFallback(iconSize: 26),
                    errorWidget: (_, _, _) =>
                        const PosterFallback(iconSize: 26),
                  ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x14050B14),
                        Color(0x66050B14),
                        Color(0xF2050B14),
                      ],
                      stops: [0, 0.45, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: TypeBadge(
                    label: isSeries ? 'Series' : 'Movie',
                    color: isSeries ? AppColors.secondary : AppColors.primary,
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: _RemoveHistoryButton(item: item),
                ),
                Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.sm,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.body.copyWith(
                          color: AppColors.text,
                          fontSize: 13,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            isSeries ? 'Series' : 'Movie',
                            style: AppType.caption.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 9,
                              letterSpacing: 0.8,
                            ),
                          ),
                          if (seasonLabel != null) ...[
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              seasonLabel,
                              style: AppType.caption.copyWith(
                                color: AppColors.primarySoft,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
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

class _RemoveHistoryButton extends StatelessWidget {
  const _RemoveHistoryButton({required this.item});

  final WatchHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Remove from watch history',
      child: Material(
        color: const Color(0x99050B14),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => WatchHistoryStore.instance.removeItem(item.id),
          child: const SizedBox(
            width: 32,
            height: 32,
            child: Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
              size: 17,
            ),
          ),
        ),
      ),
    );
  }
}
