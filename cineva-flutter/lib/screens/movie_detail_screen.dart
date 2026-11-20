import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../stores/bookmark_store.dart';
import '../stores/watch_history_store.dart';
import '../theme/app_theme.dart';
import '../widgets/cinema_ui.dart';
import '../widgets/genre_chip.dart';
import '../widgets/player_screen.dart';
import '../widgets/rating_badge.dart';
import '../widgets/states.dart';
import '../widgets/trailer_player.dart';

class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.id, this.poster});

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

  String get _heroPoster => widget.poster ?? _movie?.posterImg ?? '';

  Future<void> _watch() async {
    final movie = _movie;
    if (movie == null) return;
    WatchHistoryStore.instance.addItem(
      WatchHistoryItem(
        id: movie.id,
        title: movie.title,
        posterImg: _heroPoster,
        type: 'movie',
      ),
    );
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

  void _openPlayer(
    List<StreamSource> urls,
    String id, {
    required bool isSeries,
  }) {
    final p2p = urls
        .where((s) => s.provider.toLowerCase().contains('p2p'))
        .toList();
    final target = p2p.isNotEmpty
        ? p2p.first
        : (urls.isNotEmpty ? urls.first : null);
    final host = isSeries ? 'https://tv9.nontondrama.my' : 'https://lk21.de';
    final pageUrl = '$host/$id';
    if (target != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PlayerScreen(url: target.url, page: pageUrl),
        ),
      );
    } else {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => PlayerScreen(url: pageUrl)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: const LoadingState(label: 'Loading movie details'),
      );
    }
    if (_error != null || _movie == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: ErrorState(
          message: _error ?? 'Movie not found.',
          onRetry: _fetch,
        ),
      );
    }

    final movie = _movie!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final heroHeight = screenWidth * 1.06;
    final inList = BookmarkStore.instance.isInList(movie.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                SizedBox(
                  width: screenWidth,
                  height: heroHeight,
                  child: Hero(
                    tag: 'poster-${movie.id}',
                    child: CachedNetworkImage(
                      imageUrl: _heroPoster,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const PosterFallback(iconSize: 44),
                      errorWidget: (_, _, _) =>
                          const PosterFallback(iconSize: 44),
                    ),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x99000000),
                          Color(0x00000000),
                          Color(0xB3050B14),
                          AppColors.background,
                        ],
                        stops: [0, 0.34, 0.78, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                  left: AppSpacing.lg,
                  child: CinemaIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                  right: AppSpacing.lg,
                  child: _SaveButton(
                    active: inList,
                    onTap: () async {
                      await BookmarkStore.instance.toggle(
                        BookmarkItem(
                          id: movie.id,
                          title: movie.title,
                          posterImg: _heroPoster,
                          type: movie.type,
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                ),
                Positioned(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.xxl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TypeBadge(label: movie.type),
                          if (movie.quality.isNotEmpty) ...[
                            const SizedBox(width: AppSpacing.sm),
                            TypeBadge(
                              label: movie.quality,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.h1.copyWith(
                          fontSize: 34,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.huge,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _metaRow(movie),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _watch,
                          icon: const Icon(Icons.play_arrow_rounded, size: 23),
                          label: const Text('Play now'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(48, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _SaveAction(
                        active: inList,
                        onTap: () async {
                          await BookmarkStore.instance.toggle(
                            BookmarkItem(
                              id: movie.id,
                              title: movie.title,
                              posterImg: _heroPoster,
                              type: movie.type,
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                    ],
                  ),
                  if (movie.trailerUrl.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxxl),
                    _section('Official trailer', eyebrow: 'WATCH'),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: TrailerPlayer(url: movie.trailerUrl),
                    ),
                  ],
                  if (movie.genres.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxxl),
                    _section('Genres'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: movie.genres
                          .map((g) => GenreChip(label: g))
                          .toList(),
                    ),
                  ],
                  if (movie.synopsis.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxxl),
                    _section('Storyline'),
                    Text(movie.synopsis, style: _detailStyle()),
                  ],
                  if (movie.directors.isNotEmpty ||
                      movie.casts.isNotEmpty ||
                      movie.countries.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxxl),
                    _section('Details'),
                    _InfoPanel(
                      rows: [
                        if (movie.directors.isNotEmpty)
                          ('Director', movie.directors.join(', ')),
                        if (movie.casts.isNotEmpty)
                          ('Cast', movie.casts.join(', ')),
                        if (movie.countries.isNotEmpty)
                          ('Country', movie.countries.join(', ')),
                      ],
                    ),
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
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (movie.rating.isNotEmpty)
          RatingBadge(rating: movie.rating, medium: true),
        if (movie.releaseDate.isNotEmpty) _MetaPill(label: movie.releaseDate),
        if (movie.duration.isNotEmpty) _MetaPill(label: movie.duration),
      ],
    );
  }

  TextStyle _detailStyle() =>
      AppType.body.copyWith(color: AppColors.textSecondary, height: 1.62);

  Widget _section(String title, {String? eyebrow}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: SectionTitle(title: title, eyebrow: eyebrow),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppType.bodySmall.copyWith(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) ...[const Divider(height: AppSpacing.xxl)],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 84,
                  child: Text(
                    rows[i].$1.toUpperCase(),
                    style: AppType.caption.copyWith(
                      fontSize: 9,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    rows[i].$2,
                    style: AppType.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: active ? 'Remove from My List' : 'Add to My List',
      child: Tooltip(
        message: active ? 'Remove from My List' : 'Add to My List',
        child: Material(
          color: active ? AppColors.primary : const Color(0x66050B14),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: active
                      ? AppColors.primarySoft.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                active ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: AppColors.text,
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveAction extends StatelessWidget {
  const _SaveAction({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: active ? 'Remove from My List' : 'Add to My List',
      child: Material(
        color: active
            ? AppColors.primary.withValues(alpha: 0.14)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: active
                    ? AppColors.primary.withValues(alpha: 0.52)
                    : AppColors.border,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              active ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: active ? AppColors.primarySoft : AppColors.textSecondary,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
