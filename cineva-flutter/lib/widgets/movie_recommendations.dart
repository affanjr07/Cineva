import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/groq_client.dart';
import '../models/models.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/series_detail_screen.dart';
import '../stores/bookmark_store.dart';
import '../stores/watch_history_store.dart';
import '../theme/app_theme.dart';
import '../utils/routes.dart';
import 'cinema_ui.dart';

List<Movie>? _cachedRecommendations;
Future<List<Movie>>? _cachePromise;

class MovieRecommendations extends StatefulWidget {
  const MovieRecommendations({super.key, this.topGap = AppSpacing.section});

  final double topGap;

  @override
  State<MovieRecommendations> createState() => _MovieRecommendationsState();
}

class _MovieRecommendationsState extends State<MovieRecommendations> {
  final _client = ApiClient();
  late final SearchApi _search = SearchApi(_client);
  late final MoviesApi _moviesApi = MoviesApi(_client);

  List<Movie> _movies = [];
  bool _loading = true;

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
    final historyTitles = history.take(10).map((h) => h.title).join(', ');
    final listTitles = list.take(5).map((l) => l.title).join(', ');
    final context = [
      if (historyTitles.isNotEmpty) 'Pernah ditonton: $historyTitles',
      if (listTitles.isNotEmpty) 'Di My List: $listTitles',
      'Rekomendasikan film yang sejenis dan sesuai selera.',
    ].join('. ');

    final titles = await GroqClient.getRecommendedMovieTitles(
      context.isEmpty ? 'pengguna baru, belum ada riwayat' : context,
    );

    final found = <Movie>[];
    for (final title in titles) {
      if (found.length >= 10) break;
      try {
        final results = await _search.search(title);
        if (results.isNotEmpty) {
          final r = results.first;
          found.add(
            Movie(
              id: r.id,
              title: r.title,
              type: r.type,
              posterImg: r.posterImg,
              rating: '',
              url: r.url,
              qualityResolution: '',
              genres: r.genres,
            ),
          );
        }
      } catch (_) {}
    }

    final seen = <String>{};
    final deduped = found.where((m) => seen.add(m.id)).toList();

    return deduped.isNotEmpty
        ? deduped
        : (await _moviesApi.getPopularMovies()).take(10).toList();
  }

  Future<void> _fetchRecommendations() async {
    try {
      setState(() {
        _loading = true;
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
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _RecHeader(
        loading: true,
        title: 'Rekomendasi Film',
        topGap: widget.topGap,
      );
    }
    if (_movies.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RecHeader(
          loading: false,
          title: 'Rekomendasi Film',
          topGap: widget.topGap,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 242,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.md,
            ),
            children: [..._movies.map((m) => _RecommendationCard(movie: m))],
          ),
        ),
      ],
    );
  }
}

class _RecHeader extends StatelessWidget {
  const _RecHeader({
    required this.loading,
    required this.title,
    this.topGap = AppSpacing.section,
  });

  final bool loading;
  final String title;
  final double topGap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: CinematicSectionHeader(
        title: title,
        eyebrow: 'AI PICKS',
        trailing: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppGradients.ai,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.text,
                  size: 16,
                ),
              ),
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
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    return Semantics(
      button: true,
      label: 'Open ${movie.title}',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.96),
        onTapUp: (_) => setState(() => _scale = 1),
        onTapCancel: () => setState(() => _scale = 1),
        onTap: () {
          Navigator.of(context).push(
            cinevaPageRoute(
              movie.type == 'series'
                  ? SeriesDetailScreen(id: movie.id, poster: movie.posterImg)
                  : MovieDetailScreen(id: movie.id, poster: movie.posterImg),
            ),
          );
          if (mounted) setState(() => _scale = 1);
        },
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 118,
            margin: const EdgeInsets.only(right: AppSpacing.md),
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
                          left: AppSpacing.sm,
                          bottom: AppSpacing.sm,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0x99050B14),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 10,
                                  color: AppColors.secondarySoft,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'FOR YOU',
                                  style: AppType.caption.copyWith(
                                    color: AppColors.text,
                                    fontSize: 7.5,
                                    letterSpacing: 0.7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
            ),
          ),
        ),
      ),
    );
  }
}
