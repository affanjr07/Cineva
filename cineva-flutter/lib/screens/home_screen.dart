import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../data/home_slides.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/routes.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/cinema_ui.dart';
import '../widgets/continue_watching_row.dart';
import '../widgets/movie_recommendations.dart';
import '../widgets/movie_row.dart';
import '../widgets/states.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.isActive = true,
    this.onOpenSearch,
    this.onOpenMyList,
  });

  /// Tab Home sedang aktif di bottom navigation. Saat false, promo banner
  /// harus berhenti bersuara walau Home masih di dalam IndexedStack.
  final bool isActive;
  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenMyList;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final _client = ApiClient();
  late final MoviesApi _movies = MoviesApi(_client);
  late final SeriesApi _seriesApi = SeriesApi(_client);

  List<Movie> _trending = [];
  List<Movie> _popular = [];
  List<Movie> _topRated = [];
  List<Movie> _series = [];

  bool _loading = true;
  bool _bannerInView = true;
  bool _covered = false;
  String? _error;

  ModalRoute<Object?>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (identical(route, _route)) return;
    if (_route != null) {
      cinevaRouteObserver.unsubscribe(this);
    }
    _route = route;
    if (route != null) {
      cinevaRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPush() => _setCovered(false);

  @override
  void didPushNext() => _setCovered(true);

  @override
  void didPopNext() => _setCovered(false);

  void _setCovered(bool covered) {
    if (_covered == covered || !mounted) return;
    setState(() => _covered = covered);
  }

  @override
  void dispose() {
    cinevaRouteObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _error = null);

    // Series is fetched separately so one slow upstream endpoint cannot keep
    // the whole home screen on its skeleton.
    unawaited(_fetchSeries());

    final results = await Future.wait([
      _movies.getPopularMovies().catchError((_) => <Movie>[]),
      _movies.getTopRatedMovies().catchError((_) => <Movie>[]),
      _movies.getMovies().catchError((_) => <Movie>[]),
    ]);
    if (!mounted) return;

    final popular = results[0];
    final topRated = results[1];
    final moviesData = results[2];
    final failed = popular.isEmpty && topRated.isEmpty && moviesData.isEmpty;

    setState(() {
      _trending = popular.take(24).toList();
      _popular = (moviesData.isNotEmpty ? moviesData : popular)
          .take(24)
          .toList();
      _topRated = topRated.take(24).toList();
      _error = failed
          ? 'Failed to load movies. Please check your connection.'
          : null;
      _loading = false;
    });
  }

  Future<void> _fetchSeries() async {
    final series = await _seriesApi.getPopularSeries().catchError(
      (_) => <Movie>[],
    );
    if (!mounted) return;
    setState(() => _series = series.take(24).toList());
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _onRefresh() async {
    await _fetchData();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final bannerHeight = BannerCarousel.heightFor(context);
    final inView = notification.metrics.pixels < bannerHeight * 0.7;
    if (inView != _bannerInView && mounted) {
      setState(() => _bannerInView = inView);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: _HomeSkeleton(),
      );
    }

    if (_error != null && _trending.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorState(message: _error, onRetry: _fetchData),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl + 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HomeHeader(
                    onOpenSearch: widget.onOpenSearch,
                    onOpenMyList: widget.onOpenMyList,
                  ),
                  BannerCarousel(
                    slides: homeSlides,
                    isVisible: widget.isActive && _bannerInView && !_covered,
                  ),
                  const ContinueWatchingRow(),
                  MovieRow(
                    title: 'Trending now',
                    eyebrow: 'HOT THIS WEEK',
                    data: _trending,
                    topGap: AppSpacing.xxl,
                  ),
                  MovieRow(
                    title: 'Popular movies',
                    eyebrow: 'MOST WATCHED',
                    data: _popular,
                  ),
                  MovieRow(
                    title: 'Top rated',
                    eyebrow: 'CRITICS’ CHOICE',
                    data: _topRated,
                  ),
                  const MovieRecommendations(),
                  MovieRow(
                    title: 'Popular series',
                    eyebrow: 'BINGE-WORTHY',
                    data: _series,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onOpenSearch, required this.onOpenMyList});

  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenMyList;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          const Expanded(
            child: CinevaWordmark(compact: true, tagline: 'STREAM DIFFERENT'),
          ),
          CinemaIconButton(
            icon: Icons.search_rounded,
            tooltip: 'Search movies and series',
            onPressed: onOpenSearch,
            size: 42,
            iconSize: 19,
          ),
          const SizedBox(width: AppSpacing.sm),
          CinemaIconButton(
            icon: Icons.person_outline_rounded,
            tooltip: 'Open my account and list',
            onPressed: onOpenMyList,
            size: 42,
            iconSize: 19,
          ),
        ],
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                SkeletonBox(width: 34, height: 34, radius: 10),
                SizedBox(width: AppSpacing.sm),
                SkeletonBox(width: 104, height: 18),
                Spacer(),
                SkeletonBox(width: 42, height: 42, radius: 21),
                SizedBox(width: AppSpacing.sm),
                SkeletonBox(width: 42, height: 42, radius: 21),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              height: BannerCarousel.heightFor(context) - 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SkeletonBox(width: 150, height: 20),
            const SizedBox(height: AppSpacing.md),
            Row(children: List.generate(3, (_) => const SkeletonCard())),
          ],
        ),
      ),
    );
  }
}
