import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../screens/movie_detail_screen.dart';
import '../screens/series_detail_screen.dart';
import '../services/auth_service.dart';
import '../stores/bookmark_store.dart';
import '../stores/watch_history_store.dart';
import '../theme/app_theme.dart';
import '../utils/routes.dart';
import '../widgets/states.dart';

class MyListScreen extends StatefulWidget {
  const MyListScreen({super.key});

  @override
  State<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> {
  int _selectedTab = 0; // 0 = Bookmark / Daftar Simpan, 1 = Riwayat Nonton

  String get _accountInitial {
    final name = AuthService.instance.displayName.trim();
    return name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
  }

  String _formatTimeAgo(int timestamp) {
    if (timestamp <= 0) return '';
    final diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m lalu';
    if (diff.inHours < 24) return '${diff.inHours}j lalu';
    if (diff.inDays < 7) return '${diff.inDays}h lalu';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Hapus Semua Riwayat?', style: AppType.h3),
        content: const Text(
          'Semua riwayat film dan serial yang pernah kamu tonton akan dihapus.',
          style: AppType.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await WatchHistoryStore.instance.clearAll();
    }
  }

  Future<void> _showAccountSheet() async {
    final auth = AuthService.instance;
    final name = auth.displayName;
    final email = auth.currentUser?.email ?? '';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              0,
              AppSpacing.xxl,
              AppSpacing.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.16,
                      ),
                      child: Text(
                        _accountInitial,
                        style: AppType.h3.copyWith(
                          color: AppColors.primarySoft,
                          fontWeight: FontWeight.w800,
                        ),
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
                            style: AppType.body.copyWith(
                              color: AppColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
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
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.lg,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Title + Account Avatar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('My List', style: AppType.h1),
                  ),
                  IconButton(
                    tooltip: 'Account',
                    onPressed: _showAccountSheet,
                    icon: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        _accountInitial,
                        style: AppType.body.copyWith(
                          color: AppColors.primarySoft,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Segmented Tab Switcher: [ Daftar Simpan ] [ Riwayat Nonton ]
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _tabButton(
                        tabIndex: 0,
                        label: 'Disimpan',
                        count: BookmarkStore.instance.items.length,
                        icon: Icons.bookmark_rounded,
                      ),
                    ),
                    Expanded(
                      child: _tabButton(
                        tabIndex: 1,
                        label: 'Riwayat',
                        count: WatchHistoryStore.instance.items.length,
                        icon: Icons.history_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content List depending on active tab
            Expanded(
              child: _selectedTab == 0
                  ? _buildBookmarkTab()
                  : _buildHistoryTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton({
    required int tabIndex,
    required String label,
    required int count,
    required IconData icon,
  }) {
    final active = _selectedTab == tabIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedTab = tabIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? Colors.white : AppColors.textMuted,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkTab() {
    return ListenableBuilder(
      listenable: BookmarkStore.instance,
      builder: (context, _) {
        final items = BookmarkStore.instance.items;
        if (items.isEmpty) {
          return const EmptyState(
            title: 'Daftar Kosong',
            message: 'Film dan serial yang kamu simpan akan muncul di sini.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xxxl,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _bookmarkRow(item, index);
          },
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return ListenableBuilder(
      listenable: WatchHistoryStore.instance,
      builder: (context, _) {
        final items = WatchHistoryStore.instance.items;
        if (items.isEmpty) {
          return const EmptyState(
            title: 'Belum Ada Riwayat',
            message: 'Film dan serial yang pernah kamu tonton akan tersimpan di sini.',
          );
        }

        return Column(
          children: [
            // Clear all history header row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${items.length} tontonan terakhir',
                    style: AppType.caption.copyWith(color: AppColors.textMuted),
                  ),
                  TextButton.icon(
                    onPressed: _confirmClearHistory,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                    label: const Text('Hapus Semua', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  bottom: AppSpacing.xxxl,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _historyRow(item, index);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _bookmarkRow(BookmarkItem item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + (index % 5) * 50),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - v)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () {
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
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              CachedNetworkImage(
                imageUrl: item.posterImg,
                width: 60,
                height: 90,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => Container(
                  width: 60,
                  height: 90,
                  color: AppColors.surfaceLight,
                  child: const Center(child: Text('🎬')),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
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
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        item.type.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () async {
                  await BookmarkStore.instance.remove(item.id);
                  if (mounted) setState(() {});
                },
                icon: const Icon(
                  Icons.bookmark_remove_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _historyRow(WatchHistoryItem item, int index) {
    final isSeries = item.type == 'series';
    final timeStr = _formatTimeAgo(item.watchedAt);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 250 + (index % 5) * 50),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - v)),
          child: child,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          if (isSeries) {
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
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: item.posterImg,
                    width: 70,
                    height: 95,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      width: 70,
                      height: 95,
                      color: AppColors.surfaceLight,
                      child: const Center(child: Text('🎬')),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSeries
                                  ? AppColors.primarySoft.withValues(alpha: 0.2)
                                  : AppColors.primary,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              isSeries ? 'SERIAL' : 'FILM',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isSeries
                                    ? AppColors.primarySoft
                                    : AppColors.text,
                              ),
                            ),
                          ),
                          if (isSeries && item.season > 0) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'S${item.season} E${item.episode}',
                              style: AppType.caption.copyWith(
                                color: AppColors.primarySoft,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (timeStr.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              timeStr,
                              style: AppType.caption.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 10,
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
                tooltip: 'Hapus dari riwayat',
                onPressed: () async {
                  await WatchHistoryStore.instance.removeItem(item.id);
                  if (mounted) setState(() {});
                },
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
    );
  }
}
