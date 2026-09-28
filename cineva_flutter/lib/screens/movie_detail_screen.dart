import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../stores/bookmark_store.dart';
import '../stores/watch_history_store.dart';
import '../theme/app_theme.dart';
import '../widgets/genre_chip.dart';
import '../widgets/player_screen.dart';
import '../widgets/rating_badge.dart';
import '../widgets/states.dart';
import '../widgets/trailer_player.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({
    super.key,
    required this.id,
    this.poster,
  });

  final String id;
  final String? poster;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final _client = ApiClient();
  late final MoviesApi _movies = MoviesApi(_client);

  MovieDetails? _movie;
  List<StreamSource> _streams = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      setState(() => _error = null);
      final results = await Future.wait([
        _movies.getMovieDetails(widget.id),
        _movies.getMovieStreams(widget.id),
      ]);
      if (!mounted) return;
      setState(() {
        _movie = results[0] as MovieDetails;
        _streams = results[1] as List<StreamSource>;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load movie details.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _heroPoster =>
      widget.poster ?? _movie?.posterImg ?? '';

  Future<void> _watch() async {
    final movie = _movie;
    if (movie == null) return;
    WatchHistoryStore.instance.addItem(WatchHistoryItem(
      id: movie.id,
      title: movie.title,
      posterImg: _heroPoster,
      type: 'movie',
    ));
    var urls = _streams;
    if (urls.isEmpty) {
      try {
        urls = await _movies.getMovieStreams(movie.id);
        if (mounted) setState(() => _streams = urls);
      } catch (_) {
        urls = [];
      }
    }
    _openPlayer(urls, movie.id, isSeries: false);
  }

  void _openPlayer(List<StreamSource> urls, String id, {required bool isSeries}) {
    final p2p = urls
        .where((s) => s.provider.toLowerCase().contains('p2p'))
        .toList();
    final target = p2p.isNotEmpty ? p2p.first : (urls.isNotEmpty ? urls.first : null);
    String? pageUrl;
    final host = isSeries ? 'https://tv9.nontondrama.my' : 'https://lk21.de';
    pageUrl = '$host/$id';
    if (target != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlayerScreen(url: target.url, page: pageUrl),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlayerScreen(url: pageUrl),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingState(),
      );
    }
    if (_error != null || _movie == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorState(
          message: _error ?? 'Movie not found.',
          onRetry: _fetch,
        ),
      );
    }

    final movie = _movie!;
    final screenWidth = MediaQuery.of(context).size.width;
    final inList = BookmarkStore.instance.isInList(movie.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Hero(
                  tag: 'poster-${movie.id}',
                  child: CachedNetworkImage(
                    imageUrl: _heroPoster,
                    width: screenWidth,
                    height: screenWidth * 1.2,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      width: screenWidth,
                      height: screenWidth * 1.2,
                      color: AppColors.surface,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(color: AppColors.background.withValues(alpha: 0.4)),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + AppSpacing.lg,
                  left: AppSpacing.lg,
                  child: _roundButton(Icons.arrow_back, () => Navigator.of(context).pop()),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Text(movie.title, style: AppType.h1),
                    const SizedBox(height: AppSpacing.md),
                    _metaRow(movie),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: _primaryButton(
                            icon: Icons.play_arrow,
                            label: 'Play',
                            onTap: _watch,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _outlineButton(
                            icon: inList
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            label: inList ? 'In List' : 'My List',
                            active: inList,
                            onTap: () async {
                              await BookmarkStore.instance.toggle(BookmarkItem(
                                id: movie.id,
                                title: movie.title,
                                posterImg: _heroPoster,
                                type: movie.type,
                              ));
                              if (mounted) setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    if (movie.trailerUrl.isNotEmpty) ...[
                      _sectionTitle('Trailer'),
                      TrailerPlayer(url: movie.trailerUrl),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                    if (movie.genres.isNotEmpty) ...[
                      _sectionTitle('Genres'),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children:
                            movie.genres.map((g) => GenreChip(label: g)).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                    if (movie.synopsis.isNotEmpty) ...[
                      _sectionTitle('Synopsis'),
                      Text(movie.synopsis, style: _detailStyle()),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                    if (movie.directors.isNotEmpty) ...[
                      _sectionTitle('Directors'),
                      Text(movie.directors.join(', '), style: _detailStyle()),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                    if (movie.casts.isNotEmpty) ...[
                      _sectionTitle('Cast'),
                      Text(movie.casts.join(', '), style: _detailStyle()),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                    if (movie.countries.isNotEmpty) ...[
                      _sectionTitle('Countries'),
                      Text(movie.countries.join(', '), style: _detailStyle()),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ],
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(MovieDetails movie) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        RatingBadge(rating: movie.rating, medium: true),
        if (movie.releaseDate.isNotEmpty) ...[
          const _MetaDot(),
          Text(movie.releaseDate, style: _metaStyle()),
        ],
        if (movie.duration.isNotEmpty) ...[
          const _MetaDot(),
          Text(movie.duration, style: _metaStyle()),
        ],
        if (movie.quality.isNotEmpty) ...[
          const _MetaDot(),
          Text(movie.quality, style: _metaStyle()),
        ],
      ],
    );
  }

  TextStyle _metaStyle() => AppType.body.copyWith(color: AppColors.textSecondary);

  TextStyle _detailStyle() => AppType.body.copyWith(
        color: AppColors.textSecondary,
        height: 22 / 14,
      );

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SectionTitle(title: title),
    );
  }

  Widget _roundButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0x80000000),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.text, size: 22),
      ),
    );
  }

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.text, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(label, style: AppType.button),
            ],
          ),
        ),
      ),
    );
  }

  Widget _outlineButton({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Material(
      color: active
          ? AppColors.primary.withValues(alpha: 0.15)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.borderLight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: active
                      ? AppColors.primarySoft
                      : AppColors.textSecondary,
                  size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppType.button.copyWith(
                  fontSize: 14,
                  color: active
                      ? AppColors.primarySoft
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaDot extends StatelessWidget {
  const _MetaDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: const BoxDecoration(
        color: AppColors.textMuted,
        shape: BoxShape.circle,
      ),
    );
  }
}