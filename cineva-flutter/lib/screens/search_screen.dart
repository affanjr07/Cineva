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
import '../widgets/cinema_ui.dart';
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
  final _focusNode = FocusNode();
  List<SearchResult> _results = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;

  static const _quickSearches = [
    'Action',
    'Drama',
    'Comedy',
    'Horror',
    'Sci-Fi',
    'Romance',
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
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
      setState(() => _error = 'Search failed. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onChanged(String text) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _doSearch(text));
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    _focusNode.requestFocus();
    setState(() {
      _results = [];
      _searched = false;
      _error = null;
    });
  }

  void _searchTerm(String term) {
    _controller.text = term;
    _controller.selection = TextSelection.collapsed(offset: term.length);
    _focusNode.unfocus();
    _doSearch(term);
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
        cinevaPageRoute(MovieDetailScreen(id: item.id, poster: item.posterImg)),
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
            const ScreenHeader(
              title: 'Search',
              eyebrow: 'FIND YOUR NEXT WATCH',
              subtitle: 'Movies, series, and everything in between.',
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Semantics(
                textField: true,
                label: 'Search movies and series',
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onChanged,
                  onSubmitted: (value) {
                    _debounce?.cancel();
                    _doSearch(value);
                  },
                  textInputAction: TextInputAction.search,
                  autocorrect: false,
                  style: AppType.body.copyWith(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: 'Search movies or series...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.primarySoft,
                    ),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear search',
                            onPressed: _clear,
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.4,
                      ),
                    ),
                  ),
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
      return ErrorState(
        message: _error,
        onRetry: () => _doSearch(_controller.text),
      );
    }
    if (!_searched) {
      return _buildIdle();
    }
    if (_results.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches found',
        message: 'Try another title, or search with a shorter keyword.',
      );
    }
    return _buildResults();
  }

  Widget _buildIdle() {
    final history = SearchHistoryStore.instance.items;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.xxxl,
      ),
      children: [
        if (_loading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Searching the catalog...', style: AppType.bodySmall),
              ],
            ),
          ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  'RECENT SEARCHES',
                  style: AppType.caption.copyWith(color: AppColors.primarySoft),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    SearchHistoryStore.instance.clear();
                  });
                },
                child: const Text('Clear all'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: history
                .map(
                  (h) => _HistoryChip(
                    label: h,
                    onTap: () => _searchTerm(h),
                    onDelete: () {
                      setState(() {
                        SearchHistoryStore.instance.remove(h);
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
        Text(
          'POPULAR SEARCHES',
          style: AppType.caption.copyWith(color: AppColors.primarySoft),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: _quickSearches
              .map(
                (term) => FilterPill(
                  label: term,
                  selected: false,
                  icon: Icons.trending_up_rounded,
                  onTap: () => _searchTerm(term),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.xxxl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.primarySoft,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'Tip: search a title in English for the best results.',
                  style: AppType.bodySmall.copyWith(height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Text(
            '${_results.length} RESULTS FOR “${_controller.text.toUpperCase()}”',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppType.caption.copyWith(color: AppColors.primarySoft),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            itemCount: _results.length,
            itemBuilder: (context, index) {
              final item = _results[index];
              return _SearchResultTile(
                item: item,
                onTap: () => _openResult(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.item, required this.onTap});

  final SearchResult item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Semantics(
        button: true,
        label: '${item.title}, ${item.type}',
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 76,
                    height: 112,
                    child: CachedNetworkImage(
                      imageUrl: item.posterImg,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const PosterFallback(iconSize: 22),
                      errorWidget: (_, _, _) =>
                          const PosterFallback(iconSize: 22),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TypeBadge(
                            label: item.type,
                            color: item.type == 'series'
                                ? AppColors.secondarySoft
                                : AppColors.primary,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.title.copyWith(fontSize: 15),
                          ),
                          if (item.genres.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs + 2),
                            Text(
                              item.genres.take(3).join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: AppSpacing.md),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
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

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({
    required this.label,
    required this.onTap,
    required this.onDelete,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Container(
          constraints: const BoxConstraints(minHeight: 42),
          padding: const EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.history_rounded,
                size: 15,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: AppType.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              IconButton(
                tooltip: 'Remove $label',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
