import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../data/home_slides.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/routes.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/movie_recommendations.dart';
import '../widgets/movie_row.dart';
import '../widgets/states.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.isActive = true});

  /// Tab Home sedang aktif di bottom navigation. Saat false, promo banner
  /// harus berhenti bersuara walau Home masih di dalam IndexedStack.
  final bool isActive;

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
    try {
      setState(() => _error = null);
      final results = await Future.wait([
        _movies.getPopularMovies().catchError((_) => <Movie>[]),
        _movies.getTopRatedMovies().catchError((_) => <Movie>[]),
        _movies.getMovies().catchError((_) => <Movie>[]),
        _seriesApi.getPopularSeries().catchError((_) => <Movie>[]),
      ]);
      final popular = results[0];
      final topRated = results[1];
      final moviesData = results[2];
      final seriesData = results[3];

      setState(() {
        _trending = popular.take(24).toList();
        _popular = (moviesData.isNotEmpty ? moviesData : popular)
            .take(24)
            .toList();
        _topRated = topRated.take(24).toList();
        _series = seriesData.take(24).toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load movies. Please check your connection and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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
    if (notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical) {
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
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _buildSkeleton(),
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
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BannerCarousel(
                    slides: homeSlides,
                    isVisible:
                        widget.isActive && _bannerInView && !_covered,
                  ),
                  MovieRow(
                    title: 'Trending',
                    data: _trending,
                    topGap: AppSpacing.xxl,
                  ),
                  MovieRow(title: 'Popular Movies', data: _popular),
                  MovieRow(title: 'Top Rated', data: _topRated),
                  const MovieRecommendations(),
                  MovieRow(title: 'Popular Series', data: _series),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: MediaQuery.of(context).size.width,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: List.generate(3, (_) => const SkeletonCard()),
            ),
          ],
        ),
      ),
    );
  }
}