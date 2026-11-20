import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/movie_card.dart';
import '../widgets/states.dart';

enum GridKind { genre, country, year }

class GridScreen extends StatefulWidget {
  const GridScreen({
    super.key,
    required this.kind,
    required this.parameter,
    required this.label,
  });

  final GridKind kind;
  final String parameter;
  final String label;

  @override
  State<GridScreen> createState() => _GridScreenState();
}

class _GridScreenState extends State<GridScreen> {
  final _client = ApiClient();
  late final CatalogApi _catalog = CatalogApi(_client);

  List<Movie> _movies = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetch(refresh: true);
  }

  Future<List<Movie>> _fetchPage(int page) async {
    switch (widget.kind) {
      case GridKind.genre:
        return _catalog.getMoviesByGenre(widget.parameter, page: page);
      case GridKind.country:
        return _catalog.getMoviesByCountry(widget.parameter, page: page);
      case GridKind.year:
        return _catalog.getMoviesByYear(widget.parameter, page: page);
    }
  }

  Future<void> _fetch({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _loading = true;
        _error = null;
        _movies = [];
        _page = 0;
        _hasMore = true;
      });
    }
    try {
      final data = await _fetchPage(refresh ? 0 : _page);
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _movies = data;
        } else {
          _movies = [..._movies, ...data];
        }
        _page += 1;
        if (data.isEmpty) _hasMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (refresh) {
        setState(() => _error = 'Failed to load movies.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    await _fetch(refresh: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.label, style: AppType.h3),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingState(label: 'Loading titles');
    }
    if (_error != null && _movies.isEmpty) {
      return ErrorState(message: _error, onRetry: () => _fetch(refresh: true));
    }

    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 900
        ? 6
        : width >= 600
        ? 4
        : 3;
    final itemWidth =
        (width - AppSpacing.lg * 2 - AppSpacing.md * (columns - 1)) / columns;

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () => _fetch(refresh: true),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.lg,
          mainAxisExtent: itemWidth * 1.5 + 46,
        ),
        itemCount: _movies.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _movies.length) {
            if (_loadingMore) {
              return const LoadingState();
            }
            return Center(
              child: TextButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.expand_more_rounded, size: 18),
                label: const Text('Load more'),
              ),
            );
          }
          return MovieCard(movie: _movies[index], width: itemWidth);
        },
      ),
    );
  }
}
