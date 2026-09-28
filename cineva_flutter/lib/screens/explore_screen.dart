import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
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

  String? get _currentKey => _selected ?? (_chips.isNotEmpty ? _chips.first.key : null);

  Future<void> _loadMovies(int page, {required bool append, required String key}) async {
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
        body: LoadingState(),
      );
    }
    if (_error != null && _chips.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorState(message: _error, onRetry: _fetchLists),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: AppSpacing.md,
              ),
              child: Text('Explore', style: AppType.h1),
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                bottom: AppSpacing.md,
              ),
              child: Row(
                children: [
                  _tabPill(ExploreTab.genres, 'Genres'),
                  const SizedBox(width: AppSpacing.sm),
                  _tabPill(ExploreTab.countries, 'Countries'),
                  const SizedBox(width: AppSpacing.sm),
                  _tabPill(ExploreTab.years, 'Years'),
                ],
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.md,
                ),
                children: _chips.isEmpty
                    ? [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                          child: Text(
                            'Tidak ada data',
                            style: AppType.bodySmall,
                          ),
                        ),
                      ]
                    : _chips.map((c) {
                        final active = _currentKey == c.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selected = c.key;
                                _movies = [];
                                _visibleCount = _initialCount;
                                _page = 0;
                              });
                              _loadMovies(0,
                                  append: false, key: c.key);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xl),
                                color: active
                                    ? AppColors.primarySoft
                                    : AppColors.surface,
                                border: Border.all(
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.border,
                                ),
                              ),
                              child: Text(
                                c.label,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: active
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: active
                                      ? AppColors.text
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
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
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisExtent: 240,
                  ),
                  itemCount: _movies.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _movies.length) {
                      if (_movies.isEmpty) {
                        return _loadingMovies
                            ? const LoadingState()
                            : Center(
                                child: Text(
                                  'Belum ada film di sini.',
                                  style: AppType.body.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Center(
                          child: TextButton(
                            onPressed: _loadingMovies ? null : _showMore,
                            child: _loadingMovies
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primarySoft,
                                    ),
                                  )
                                : const Text(
                                    'Load More',
                                    style: TextStyle(
                                      color: AppColors.primarySoft,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(
                            milliseconds: 300 + (index % 6) * 60,
                          ),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, child) => Opacity(
                            opacity: v,
                            child: Transform.translate(
                              offset: Offset(0, 14 * (1 - v)),
                              child: child,
                            ),
                          ),
                          child: MovieCard(movie: _movies[index]),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (_movies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(
                    left: AppSpacing.lg, bottom: AppSpacing.lg),
                child: Text(
                  '${_labelFor(_currentKey)} • ${_movies.length} film',
                  style: AppType.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
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
    return GestureDetector(
      onTap: () => _selectTab(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          color: active ? AppColors.primary : AppColors.surfaceLight,
        ),
        child: Text(
          label,
          style: AppType.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.text : AppColors.textSecondary,
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