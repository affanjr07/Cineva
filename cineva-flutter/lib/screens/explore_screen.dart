import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/cinema_ui.dart';
import '../widgets/movie_card.dart';
import '../widgets/states.dart';

enum ExploreTab { genres, countries, years }

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _client = ApiClient();
  late final CatalogApi _catalog = CatalogApi(_client);

  ExploreTab _activeTab = ExploreTab.genres;
  List<Genre> _genres = [];
  List<Country> _countries = [];
  List<Year> _years = [];
  String? _selected;

  List<Movie> _movies = [];
  bool _loading = true;
  bool _loadingMovies = false;
  String? _error;
  int _visibleCount = 6;
  int _page = 0;

  static const _initialCount = 6;
  static const _loadStep = 12;

  @override
  void initState() {
    super.initState();
    _fetchLists();
  }

  Future<void> _fetchLists() async {
    try {
      setState(() => _error = null);
      final genresF = _catalog.getGenres();
      final countriesF = _catalog.getCountries();
      final yearsF = _catalog.getYears();
      var loaded = 0;
      final genres = await genresF;
      if (genres.isNotEmpty) {
        setState(() => _genres = genres);
        loaded++;
      }
      final countries = await countriesF;
      if (countries.isNotEmpty) {
        setState(() => _countries = countries);
        loaded++;
      }
      final years = await yearsF;
      if (years.isNotEmpty) {
        setState(() => _years = years);
        loaded++;
      }
      if (loaded == 0) {
        setState(() => _error = 'No explore data available.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Failed to load explore data.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (mounted) {
      await _loadMovies(0, append: false, key: _currentKey ?? '');
    }
  }

  List<_ChipData> get _chips {
    switch (_activeTab) {
      case ExploreTab.genres:
        return _genres.map((g) => _ChipData(g.parameter, g.name)).toList();
      case ExploreTab.countries:
        return _countries.map((c) => _ChipData(c.parameter, c.name)).toList();
      case ExploreTab.years:
        return _years.map((y) => _ChipData(y.parameter, y.parameter)).toList();
    }
  }

  String? get _currentKey =>
      _selected ?? (_chips.isNotEmpty ? _chips.first.key : null);

  Future<void> _loadMovies(
    int page, {
    required bool append,
    required String key,
  }) async {
    if (key.isEmpty) return;
    setState(() => _loadingMovies = true);
    try {
      List<Movie> data;
      switch (_activeTab) {
        case ExploreTab.genres:
          data = await _catalog.getMoviesByGenre(key, page: page);
          break;
        case ExploreTab.countries:
          data = await _catalog.getMoviesByCountry(key, page: page);
          break;
        case ExploreTab.years:
          data = await _catalog.getMoviesByYear(key, page: page);
          break;
      }
      if (!mounted) return;
      setState(() {
        if (append) {
          _movies = [..._movies, ...data];
        } else {
          _movies = data;
          _visibleCount = _initialCount;
          _page = 0;
        }
      });
    } catch (_) {
      if (!append && mounted) {
        setState(() => _movies = []);
      }
    } finally {
      if (mounted) setState(() => _loadingMovies = false);
    }
  }

  void _selectTab(ExploreTab tab) {
    setState(() {
      _activeTab = tab;
      _selected = null;
      _movies = [];
      _visibleCount = _initialCount;
      _page = 0;
    });
    _loadMovies(0, append: false, key: _currentKey ?? '');
  }

  Future<void> _onRefresh() async {
    await _fetchLists();
    await _loadMovies(0, append: false, key: _currentKey ?? '');
  }

  void _showMore() {
    final next = _visibleCount + _loadStep;
    if (!_loadingMovies && next <= _movies.length) {
      setState(() => _visibleCount = next);
    } else {
      final nextPage = _page + 1;
      _page = nextPage;
      _loadMovies(nextPage, append: true, key: _currentKey ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: LoadingState(label: 'Loading the catalog'),
      );
    }
    if (_error != null && _chips.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorState(message: _error, onRetry: _fetchLists),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 900
        ? 6
        : width >= 600
        ? 4
        : 3;
    final itemWidth =
        (width - AppSpacing.lg * 2 - AppSpacing.md * (columns - 1)) / columns;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(
              title: 'Explore',
              eyebrow: 'DISCOVER',
              subtitle: 'Find something new by genre, country, or year.',
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _tabSelector(),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                ),
                children: _chips.isEmpty
                    ? [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                          child: Text(
                            'No filters available',
                            style: AppType.bodySmall,
                          ),
                        ),
                      ]
                    : _chips.map((c) {
                        final active = _currentKey == c.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: FilterPill(
                            label: c.label,
                            selected: active,
                            onTap: () {
                              setState(() {
                                _selected = c.key;
                                _movies = [];
                                _visibleCount = _initialCount;
                                _page = 0;
                              });
                              _loadMovies(0, append: false, key: c.key);
                            },
                          ),
                        );
                      }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _labelFor(_currentKey).isNotEmpty
                          ? _labelFor(_currentKey).toUpperCase()
                          : 'BROWSE',
                      style: AppType.caption.copyWith(
                        color: AppColors.primarySoft,
                      ),
                    ),
                  ),
                  if (_movies.isNotEmpty)
                    Text('${_movies.length} TITLES', style: AppType.caption),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                onRefresh: _onRefresh,
                child: GridView.builder(
                  key: ValueKey('$_activeTab-$_currentKey'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.xxxl,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.lg,
                    mainAxisExtent: itemWidth * 1.5 + 46,
                  ),
                  itemCount: _movies.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _movies.length) {
                      if (_movies.isEmpty) {
                        return _loadingMovies
                            ? const LoadingState()
                            : Center(
                                child: Text(
                                  'No titles here yet.',
                                  style: AppType.body.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                      }
                      return Center(
                        child: TextButton.icon(
                          onPressed: _loadingMovies ? null : _showMore,
                          icon: _loadingMovies
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more_rounded, size: 18),
                          label: Text(_loadingMovies ? 'Loading' : 'Load more'),
                        ),
                      );
                    }
                    final reduceMotion = MediaQuery.of(context)
                        .disableAnimations;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: reduceMotion
                          ? Duration.zero
                          : Duration(milliseconds: 300 + (index % 6) * 55),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, child) => Opacity(
                        opacity: v,
                        child: Transform.translate(
                          offset: Offset(0, 14 * (1 - v)),
                          child: child,
                        ),
                      ),
                      child: MovieCard(movie: _movies[index], width: itemWidth),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _tabPill(ExploreTab.genres, 'Genres'),
          _tabPill(ExploreTab.countries, 'Countries'),
          _tabPill(ExploreTab.years, 'Years'),
        ],
      ),
    );
  }

  String _labelFor(String? key) {
    if (key == null) return '';
    final chip = _chips.where((c) => c.key == key).toList();
    return chip.isNotEmpty ? chip.first.label : '';
  }

  Widget _tabPill(ExploreTab tab, String label) {
    final active = _activeTab == tab;
    return Expanded(
      child: Semantics(
        selected: active,
        button: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () => _selectTab(tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: AppType.bodySmall.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: active ? AppColors.text : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipData {
  final String key;
  final String label;
  const _ChipData(this.key, this.label);
}
