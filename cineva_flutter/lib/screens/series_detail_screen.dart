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

class SeriesDetailScreen extends StatefulWidget {
  const SeriesDetailScreen({
    super.key,
    required this.id,
    this.poster,
  });

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

  String get _heroPoster =>
      widget.poster ?? _seriesData?.posterImg ?? '';

  Future<void> _watch() async {
    final series = _seriesData;
    if (series == null) return;
    WatchHistoryStore.instance.addItem(WatchHistoryItem(
      id: series.id,
      title: series.title,
      posterImg: _heroPoster,
      type: 'series',
      season: _selectedSeason,
      episode: _selectedEpisode,
    ));
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
    final pageUrl =
        'https://tv9.nontondrama.my/${widget.id}';
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
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingState(),
      );
    }
    if (_error != null || _seriesData == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorState(
          message: _error ?? 'Series not found.',
          onRetry: _fetch,
        ),
      );
    }
    final series = _seriesData!;
    final screenWidth = MediaQuery.of(context).size.width;
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
                Hero(
                  tag: 'poster-${series.id}',
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
                  child: Container(
                      color: AppColors.background.withValues(alpha: 0.4)),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + AppSpacing.lg,
                  left: AppSpacing.lg,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0x80000000),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.text, size: 22),
                    ),
                  ),
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
                    Text(series.title, style: AppType.h1),
                    const SizedBox(height: AppSpacing.md),
                    _metaRow(series),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: _primaryButton(
                            icon: Icons.play_arrow,
                            label: 'Watch',
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
                              await BookmarkStore.instance.toggle(
                                  BookmarkItem(
                                    id: series.id,
                                    title: series.title,
                                    posterImg: _heroPoster,
                                    type: series.type,
                                  ));
                              if (mounted) setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    if (series.trailerUrl.isNotEmpty) ...[
                      _sectionTitle('Trailer'),
                      TrailerPlayer(url: series.trailerUrl),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                    if (series.seasons.isNotEmpty) ...[
                      _sectionTitle('Seasons'),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: series.seasons.length,
                          separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final s = series.seasons[index];
                            final active = s.season == _selectedSeason;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedSeason = s.season;
                                  _selectedEpisode = 1;
                                  _showStreams = false;
                                });
                              },
                              child: _pill(
                                'Season ${s.season}',
                                active,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                    if (currentSeason.isNotEmpty) ...[
                      _sectionTitle('Episodes (Season $_selectedSeason)'),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: List.generate(
                          currentSeason.first.totalEpisodes,
                          (i) {
                            final ep = i + 1;
                            final active = ep == _selectedEpisode;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedEpisode = ep;
                                  _showStreams = false;
                                });
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.surfaceLight,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: active
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  '$ep',
                                  style: AppType.body.copyWith(
                                    color: active
                                        ? AppColors.text
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                    if (_showStreams && _streams.isNotEmpty) ...[
                      _sectionTitle('Choose Source'),
                      ..._streams.map((stream) => _streamTile(stream)),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                    if (series.genres.isNotEmpty) ...[
                      _sectionTitle('Genres'),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: series.genres
                            .map((g) => GenreChip(label: g))
                            .toList(),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                    if (series.synopsis.isNotEmpty) ...[
                      _sectionTitle('Synopsis'),
                      Text(series.synopsis, style: _detailStyle()),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                    if (series.directors.isNotEmpty) ...[
                      _sectionTitle('Directors'),
                      Text(series.directors.join(', '), style: _detailStyle()),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                    if (series.casts.isNotEmpty) ...[
                      _sectionTitle('Cast'),
                      Text(series.casts.join(', '), style: _detailStyle()),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                    if (series.countries.isNotEmpty) ...[
                      _sectionTitle('Countries'),
                      Text(series.countries.join(', '), style: _detailStyle()),
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

  Widget _streamTile(StreamSource stream) {
    return GestureDetector(
      onTap: () => _selectStream(stream),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stream.provider,
                    style: AppType.body.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    stream.resolutions.join(' • '),
                    style: AppType.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new,
                size: 18, color: AppColors.primarySoft),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(SeriesDetails series) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        RatingBadge(rating: series.rating, medium: true),
        if (series.status.isNotEmpty) ...[
          const _MetaDot(),
          Text(
            series.status,
            style: AppType.body.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
        if (series.releaseDate.isNotEmpty) ...[
          const _MetaDot(),
          Text(series.releaseDate,
              style: AppType.body.copyWith(color: AppColors.textSecondary)),
        ],
      ],
    );
  }

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

  Widget _pill(String label, bool active) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        color: active ? AppColors.primary : AppColors.surfaceLight,
        border: Border.all(
          color: active ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: AppType.body.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: active ? AppColors.text : AppColors.textSecondary,
        ),
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