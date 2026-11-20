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

class SeriesDetailScreen extends StatefulWidget {
  const SeriesDetailScreen({super.key, required this.id, this.poster});

  final String id;
  final String? poster;

  @override
  State<SeriesDetailScreen> createState() => _SeriesDetailScreenState();
}

class _SeriesDetailScreenState extends State<SeriesDetailScreen> {
  final _client = ApiClient();
  late final SeriesApi _series = SeriesApi(_client);

  SeriesDetails? _seriesData;
  bool _loading = true;
  String? _error;
  int _selectedSeason = 1;
  int _selectedEpisode = 1;
  bool _showStreams = false;
  List<StreamSource> _streams = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      setState(() => _error = null);
      final data = await _series.getSeriesDetails(widget.id);
      if (!mounted) return;
      setState(() => _seriesData = data);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load series details.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _heroPoster => widget.poster ?? _seriesData?.posterImg ?? '';

  Future<void> _watch() async {
    final series = _seriesData;
    if (series == null) return;
    WatchHistoryStore.instance.addItem(
      WatchHistoryItem(
        id: series.id,
        title: series.title,
        posterImg: _heroPoster,
        type: 'series',
        season: _selectedSeason,
        episode: _selectedEpisode,
      ),
    );
    List<StreamSource> urls = [];
    try {
      urls = await _series.getSeriesStreams(
        series.id,
        season: _selectedSeason,
        episode: _selectedEpisode,
      );
      if (mounted) {
        setState(() {
          _streams = urls;
          _showStreams = true;
        });
      }
    } catch (_) {
      urls = [];
    }
    _openPlayer(urls);
  }

  void _openPlayer(List<StreamSource> urls) {
    final p2p = urls
        .where((s) => s.provider.toLowerCase().contains('p2p'))
        .toList();
    final target = p2p.isNotEmpty
        ? p2p.first
        : (urls.isNotEmpty ? urls.first : null);
    final pageUrl = 'https://tv9.nontondrama.my/${widget.id}';
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

  void _selectStream(StreamSource stream) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlayerScreen(
          url: stream.url,
          page: 'https://tv9.nontondrama.my/${widget.id}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: const LoadingState(label: 'Loading series details'),
      );
    }
    if (_error != null || _seriesData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(),
        body: ErrorState(
          message: _error ?? 'Series not found.',
          onRetry: _fetch,
        ),
      );
    }

    final series = _seriesData!;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final heroHeight = screenWidth * 1.06;
    final inList = BookmarkStore.instance.isInList(series.id);
    final currentSeason = series.seasons
        .where((s) => s.season == _selectedSeason)
        .toList();

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
                    tag: 'poster-${series.id}',
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
                          id: series.id,
                          title: series.title,
                          posterImg: _heroPoster,
                          type: series.type,
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
                          TypeBadge(
                            label: series.type,
                            color: AppColors.secondarySoft,
                          ),
                          if (series.status.isNotEmpty) ...[
                            const SizedBox(width: AppSpacing.sm),
                            TypeBadge(
                              label: series.status,
                              color: AppColors.success,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        series.title,
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
                  _metaRow(series),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _watch,
                          icon: const Icon(Icons.play_arrow_rounded, size: 23),
                          label: Text(
                            'Watch S$_selectedSeason E$_selectedEpisode',
                          ),
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
                              id: series.id,
                              title: series.title,
                              posterImg: _heroPoster,
                              type: series.type,
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                      ),
                    ],
                  ),
                  if (series.trailerUrl.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxxl),
                    _section('Official trailer', eyebrow: 'WATCH'),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: TrailerPlayer(url: series.trailerUrl),
                    ),
                  ],
                  if (series.seasons.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxxl),
                    _section('Seasons'),
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: series.seasons.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final s = series.seasons[index];
                          final active = s.season == _selectedSeason;
                          return FilterPill(
                            label: 'Season ${s.season}',
                            selected: active,
                            onTap: () {
                              setState(() {
                                _selectedSeason = s.season;
                                _selectedEpisode = 1;
                                _showStreams = false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  if (currentSeason.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxl),
                    _section('Episodes', eyebrow: 'SEASON $_selectedSeason'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: List.generate(
                        currentSeason.first.totalEpisodes,
                        (i) {
                          final ep = i + 1;
                          final active = ep == _selectedEpisode;
                          return Semantics(
                            button: true,
                            selected: active,
                            label: 'Episode $ep',
                            child: Material(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedEpisode = ep;
                                    _showStreams = false;
                                  });
                                },
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                    border: Border.all(
                                      color: active
                                          ? AppColors.primarySoft.withValues(
                                              alpha: 0.3,
                                            )
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Text(
                                    '$ep',
                                    style: AppType.body.copyWith(
                                      color: active
                                          ? AppColors.text
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (_showStreams && _streams.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxxl),
                    _section('Choose a source', eyebrow: 'STREAM'),
                    ..._streams.map((stream) => _streamTile(stream)),
                  ],
                  if (series.genres.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxxl),
                    _section('Genres'),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: series.genres
                          .map((g) => GenreChip(label: g))
                          .toList(),
                    ),
                  ],
                  if (series.synopsis.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxxl),
                    _section('Storyline'),
                    Text(series.synopsis, style: _detailStyle()),
                  ],
                  if (series.directors.isNotEmpty ||
                      series.casts.isNotEmpty ||
                      series.countries.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxxl),
                    _section('Details'),
                    _InfoPanel(
                      rows: [
                        if (series.directors.isNotEmpty)
                          ('Director', series.directors.join(', ')),
                        if (series.casts.isNotEmpty)
                          ('Cast', series.casts.join(', ')),
                        if (series.countries.isNotEmpty)
                          ('Country', series.countries.join(', ')),
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

  Widget _streamTile(StreamSource stream) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _selectStream(stream),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 20,
                  color: AppColors.primarySoft,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stream.provider,
                      style: AppType.body.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (stream.resolutions.isNotEmpty)
                      Text(
                        stream.resolutions.join(' · '),
                        style: AppType.bodySmall,
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.open_in_new_rounded,
                size: 17,
                color: AppColors.primarySoft,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaRow(SeriesDetails series) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (series.rating.isNotEmpty)
          RatingBadge(rating: series.rating, medium: true),
        if (series.releaseDate.isNotEmpty) _MetaPill(label: series.releaseDate),
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
            if (i > 0) const Divider(height: AppSpacing.xxl),
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
