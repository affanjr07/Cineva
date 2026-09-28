import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../screens/movie_detail_screen.dart';
import '../screens/series_detail_screen.dart';
import '../stores/search_history_store.dart';
import '../theme/app_theme.dart';
import '../utils/routes.dart';
import '../widgets/states.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _client = ApiClient();
  late final SearchApi _searchApi = SearchApi(_client);

  final _controller = TextEditingController();
  Timer? _debounce;
  List<SearchResult> _results = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _doSearch(String text) async {
    if (text.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _searchApi.search(text);
      if (!mounted) return;
      setState(() {
        _results = data;
        _searched = true;
      });
      SearchHistoryStore.instance.add(text);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Search failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _doSearch(text));
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _results = [];
      _searched = false;
      _error = null;
    });
  }

  void _openResult(SearchResult item) {
    FocusScope.of(context).unfocus();
    if (item.type == 'series') {
      Navigator.of(context).push(
        cinevaPageRoute(
          SeriesDetailScreen(id: item.id, poster: item.posterImg),
        ),
      );
    } else {
      Navigator.of(context).push(
        cinevaPageRoute(
          MovieDetailScreen(id: item.id, poster: item.posterImg),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: AppSpacing.md),
                    const Icon(Icons.search,
                        size: 18, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onChanged: _onChanged,
                        textInputAction: TextInputAction.search,
                        autocorrect: false,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search movies or series...',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
                        ),
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        onPressed: _clear,
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.cancel,
                            size: 18, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return ErrorState(message: _error, onRetry: () => _doSearch(_controller.text));
    }
    if (!_searched) {
      return _buildIdle();
    }
    if (_results.isEmpty) {
      return const EmptyState(
        title: 'No results found',
        message: 'No movies or series found. Try another search.',
      );
    }
    return _buildResults();
  }

  Widget _buildIdle() {
    final history = SearchHistoryStore.instance.items;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: [
        if (_loading)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primarySoft,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Mencari...',
                  style: AppType.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        if (history.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Riwayat Pencarian',
                        style: AppType.h3.copyWith(fontSize: 17)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          SearchHistoryStore.instance.clear();
                        });
                      },
                      child: const Text(
                        'Hapus Semua',
                        style: TextStyle(
                          color: AppColors.primarySoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: history.map((h) {
                    return InputChip(
                      backgroundColor: AppColors.surface,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      avatar: const Icon(Icons.history,
                          size: 14, color: AppColors.textSecondary),
                      label: Text(
                        h,
                        style: AppType.body.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      deleteIcon: const Icon(Icons.close,
                          size: 14, color: AppColors.textMuted),
                      onDeleted: () {
                        setState(() {
                          SearchHistoryStore.instance.remove(h);
                        });
                      },
                      onPressed: () {
                        _controller.text = h;
                        _doSearch(h);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildResults() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final item = _results[index];
        return GestureDetector(
          onTap: () => _openResult(item),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Hero(
                  tag: 'poster-${item.id}',
                  child: CachedNetworkImage(
                    imageUrl: item.posterImg,
                    width: 70,
                    height: 100,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      width: 70,
                      height: 100,
                      color: AppColors.surfaceLight,
                      child: const Center(child: Text('🎬')),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.body.copyWith(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            item.type.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        if (item.genres.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            item.genres.take(3).join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}