import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/gemini_client.dart';
import '../models/models.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/series_detail_screen.dart';
import '../stores/bookmark_store.dart';
import '../stores/watch_history_store.dart';
import '../theme/app_theme.dart';
import '../utils/routes.dart';

List<Movie>? _cachedRecommendations;
Future<List<Movie>>? _cachePromise;

class MovieRecommendations extends StatefulWidget {
  const MovieRecommendations({super.key});

  @override
  State<MovieRecommendations> createState() => _MovieRecommendationsState();
}

class _MovieRecommendationsState extends State<MovieRecommendations> {
  final _client = ApiClient();
  late final SearchApi _search = SearchApi(_client);
  late final MoviesApi _moviesApi = MoviesApi(_client);

  List<Movie> _movies = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WatchHistoryStore.instance.addListener(_onStoresChanged);
    BookmarkStore.instance.addListener(_onStoresChanged);
    _fetchRecommendations();
  }

  @override
  void dispose() {
    WatchHistoryStore.instance.removeListener(_onStoresChanged);
    BookmarkStore.instance.removeListener(_onStoresChanged);
    super.dispose();
  }

  void _onStoresChanged() {
    _cachedRecommendations = null;
    _cachePromise = null;
    if (mounted) _fetchRecommendations();
  }

  Future<List<Movie>> _generate() async {
    final history = WatchHistoryStore.instance.items;
    final list = BookmarkStore.instance.items;
    final historyTitles =
        history.take(10).map((h) => h.title).join(', ');
    final listTitles = list.take(5).map((l) => l.title).join(', ');
    final context = [
      if (historyTitles.isNotEmpty) 'Pernah ditonton: $historyTitles',
      if (listTitles.isNotEmpty) 'Di My List: $listTitles',
      'Rekomendasikan film yang sejenis dan sesuai selera.',
    ].join('. ');

    final titles = await GeminiClient.getRecommendedMovieTitles(
      context.isEmpty ? 'pengguna baru, belum ada riwayat' : context,
    );

    final found = <Movie>[];
    for (final title in titles) {
      if (found.length >= 10) break;
      try {
        final results = await _search.search(title);
        if (results.isNotEmpty) {
          final r = results.first;
          found.add(Movie(
            id: r.id,
            title: r.title,
            type: r.type,
            posterImg: r.posterImg,
            rating: '',
            url: r.url,
            qualityResolution: '',
            genres: r.genres,
          ));
        }
      } catch (_) {}
    }

    final seen = <String>{};
    final deduped =
        found.where((m) => seen.add(m.id)).toList();

    return deduped.isNotEmpty
        ? deduped
        : (await _moviesApi.getPopularMovies()).take(10).toList();
  }

  Future<void> _fetchRecommendations() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      if (_cachedRecommendations != null) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        if (!mounted) return;
        setState(() {
          _movies = _cachedRecommendations!;
          _loading = false;
        });
        return;
      }

      _cachePromise ??= _generate();
      final result = await _cachePromise!;
      _cachedRecommendations = result;
      if (!mounted) return;
      setState(() {
        _movies = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Tidak dapat memuat rekomendasi.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _RecHeader(
        loading: true,
        title: 'Rekomendasi Film',
      );
    }
    if (_movies.isEmpty) {
      if (_error != null) return const SizedBox.shrink();
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _RecHeader(loading: false, title: 'Rekomendasi Film'),
        SizedBox(
          height: 230,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.md,
            ),
            children: [
              ..._movies.map((m) => _RecommendationCard(movie: m)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _RecHeader extends StatelessWidget {
  const _RecHeader({required this.loading, required this.title});

  final bool loading;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        bottom: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primarySoft.withValues(alpha: 0.15),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.primarySoft,
              size: 13,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(title, style: AppType.h3),
          if (loading) ...[
            const SizedBox(width: AppSpacing.sm),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primarySoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatefulWidget {
  const _RecommendationCard({required this.movie});

  final Movie movie;

  @override
  State<_RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<_RecommendationCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: () {
        Navigator.of(context).push(
          cinevaPageRoute(
            movie.type == 'series'
                ? SeriesDetailScreen(id: movie.id, poster: movie.posterImg)
                : MovieDetailScreen(id: movie.id, poster: movie.posterImg),
          ),
        );
        if (mounted) setState(() => _scale = 1.0);
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 110,
          margin: const EdgeInsets.only(right: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 110,
                    height: 165,
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
                  if (movie.rating.isNotEmpty)
                    Positioned(
                      bottom: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          '⭐ ${movie.rating}',
                          style: const TextStyle(
                            color: AppColors.rating,
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
            ],
          ),
        ),
      ),
    );
  }
}
