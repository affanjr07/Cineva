import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../screens/movie_detail_screen.dart';
import '../screens/series_detail_screen.dart';
import '../services/auth_service.dart';
import '../stores/bookmark_store.dart';
import '../stores/watch_history_store.dart';
import '../theme/app_theme.dart';
import '../utils/routes.dart';
import '../widgets/cinema_ui.dart';
import '../widgets/states.dart';

class MyListScreen extends StatefulWidget {
  const MyListScreen({super.key, this.onExplore});

  final VoidCallback? onExplore;

  @override
  State<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> {
  int _selectedTab = 0; // 0 = saved, 1 = watch history

  late final _libraryListenable = Listenable.merge([
    BookmarkStore.instance,
    WatchHistoryStore.instance,
  ]);

  String get _accountInitial {
    final name = AuthService.instance.displayName.trim();
    return name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
  }

  String _formatTimeAgo(int timestamp) {
    if (timestamp <= 0) return '';
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear watch history?', style: AppType.h3),
        content: Text(
          'This removes all movies and series from your watch history. '
          'This cannot be undone.',
          style: AppType.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await WatchHistoryStore.instance.clearAll();
    }
  }

  void _openTitle(String id, String type, String poster) {
    if (type == 'series') {
      Navigator.of(context)
          .push(cinevaPageRoute(SeriesDetailScreen(id: id, poster: poster)));
    } else {
      Navigator.of(context)
          .push(cinevaPageRoute(MovieDetailScreen(id: id, poster: poster)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _libraryListenable,
      builder: (context, _) {
        final saved = BookmarkStore.instance.items;
        final history = WatchHistoryStore.instance.items;
        final showingSaved = _selectedTab == 0;

        final subtitle = showingSaved
            ? (saved.isEmpty
                  ? 'Save films and series to watch them later.'
                  : '${saved.length} saved ${saved.length == 1 ? 'title' : 'titles'} ready when you are.')
            : (history.isEmpty
                  ? 'Movies and series you play will show up here.'
                  : '${history.length} recently watched ${history.length == 1 ? 'title' : 'titles'}.');

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScreenHeader(
                  title: 'My List',
                  eyebrow: 'YOUR LIBRARY',
                  subtitle: subtitle,
                  trailing: _AccountButton(
                    initial: _accountInitial,
                    onTap: _showAccountSheet,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: _LibraryTabs(
                    selectedIndex: _selectedTab,
                    savedCount: saved.length,
                    historyCount: history.length,
                    onChanged: (index) {
                      if (index != _selectedTab) {
                        setState(() => _selectedTab = index);
                      }
                    },
                  ),
                ),
                Expanded(
                  child: showingSaved
                      ? _buildSavedList(saved)
                      : _buildHistoryList(history),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedList(List<BookmarkItem> items) {
    if (items.isEmpty) {
      return EmptyState(
        icon: Icons.bookmark_border_rounded,
        title: 'Your list is empty',
        message:
            'Tap the bookmark on any movie or series and it will appear here.',
        actionLabel: 'Explore movies',
        onAction: widget.onExplore,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _SavedTile(
          item: item,
          index: index,
          onOpen: () => _openTitle(item.id, item.type, item.posterImg),
          onRemove: () async {
            await BookmarkStore.instance.remove(item.id);
            if (mounted) setState(() {});
          },
        );
      },
    );
  }

  Widget _buildHistoryList(List<WatchHistoryItem> items) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'No watch history yet',
        message: 'Movies and series you play will show up here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${items.length} ${items.length == 1 ? 'recent title' : 'recent titles'}',
                  style: AppType.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ),
              TextButton.icon(
                onPressed: _confirmClearHistory,
                icon: const Icon(Icons.delete_sweep_outlined, size: 17),
                label: const Text('Clear all'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  visualDensity: VisualDensity.compact,
                  minimumSize: const Size(48, 40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  textStyle: AppType.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
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
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _HistoryTile(
                item: item,
                index: index,
                timeAgo: _formatTimeAgo(item.watchedAt),
                onOpen: () => _openTitle(item.id, item.type, item.posterImg),
                onRemove: () async {
                  await WatchHistoryStore.instance.removeItem(item.id);
                  if (mounted) setState(() {});
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAccountSheet() async {
    final auth = AuthService.instance;
    final name = auth.displayName;
    final email = auth.currentUser?.email ?? '';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.sm,
            AppSpacing.xxl,
            AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: AppGradients.accentGlow,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _accountInitial,
                      style: AppType.h2.copyWith(color: AppColors.text),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.title.copyWith(fontSize: 17),
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      color: AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Signed in securely with Supabase',
                        style: AppType.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  try {
                    await auth.signOut();
                  } catch (error) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(auth.friendlyError(error))),
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded, size: 19),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(
                    color: AppColors.error.withValues(alpha: 0.42),
                  ),
                  minimumSize: const Size(48, 54),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LibraryTabs extends StatelessWidget {
  const _LibraryTabs({
    required this.selectedIndex,
    required this.savedCount,
    required this.historyCount,
    required this.onChanged,
  });

  final int selectedIndex;
  final int savedCount;
  final int historyCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LibraryTabButton(
              label: 'Saved',
              icon: Icons.bookmark_rounded,
              count: savedCount,
              active: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _LibraryTabButton(
              label: 'History',
              icon: Icons.history_rounded,
              count: historyCount,
              active: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryTabButton extends StatelessWidget {
  const _LibraryTabButton({
    required this.label,
    required this.icon,
    required this.count,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final int count;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = active ? AppColors.text : AppColors.textMuted;
    return Semantics(
      button: true,
      selected: active,
      label: count > 0 ? '$label, $count' : label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppType.bodySmall.copyWith(
                    color: foreground,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: active
                          ? Colors.white.withValues(alpha: 0.22)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '$count',
                      style: AppType.caption.copyWith(
                        color: foreground,
                        fontSize: 9,
                        letterSpacing: 0.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton({required this.initial, required this.onTap});

  final String initial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open account menu',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppGradients.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: AppType.title.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.item,
    required this.index,
    required this.timeAgo,
    required this.onOpen,
    required this.onRemove,
  });

  final WatchHistoryItem item;
  final int index;
  final String timeAgo;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final isSeries = item.type == 'series';
    final seasonLabel = isSeries && item.season > 0
        ? 'S${item.season} E${item.episode}'
        : null;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : Duration(milliseconds: 260 + (index % 5) * 50),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Semantics(
          button: true,
          label: '${item.title}, ${isSeries ? 'series' : 'movie'}',
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onOpen,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      height: 104,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (item.posterImg.isEmpty)
                            const PosterFallback(iconSize: 20)
                          else
                            CachedNetworkImage(
                              imageUrl: item.posterImg,
                              fit: BoxFit.cover,
                              placeholder: (_, _) =>
                                  const PosterFallback(iconSize: 20),
                              errorWidget: (_, _, _) =>
                                  const PosterFallback(iconSize: 20),
                            ),
                          Center(
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: AppColors.text,
                                size: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                TypeBadge(
                                  label: isSeries ? 'Series' : 'Movie',
                                  color: isSeries
                                      ? AppColors.secondary
                                      : AppColors.primary,
                                ),
                                if (seasonLabel != null) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    seasonLabel,
                                    style: AppType.caption.copyWith(
                                      color: AppColors.primarySoft,
                                      fontSize: 9,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.title.copyWith(fontSize: 15),
                            ),
                            if (timeAgo.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeAgo,
                                    style: AppType.bodySmall.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove from watch history',
                      onPressed: onRemove,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedTile extends StatelessWidget {
  const _SavedTile({
    required this.item,
    required this.index,
    required this.onOpen,
    required this.onRemove,
  });

  final BookmarkItem item;
  final int index;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion
          ? Duration.zero
          : Duration(milliseconds: 280 + (index % 5) * 55),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - v)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: Semantics(
          button: true,
          label: '${item.title}, ${item.type}',
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onOpen,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      height: 104,
                      child: CachedNetworkImage(
                        imageUrl: item.posterImg,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            const PosterFallback(iconSize: 20),
                        errorWidget: (_, _, _) =>
                            const PosterFallback(iconSize: 20),
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
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove ${item.title} from My List',
                      onPressed: onRemove,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.textMuted,
                        size: 21,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
