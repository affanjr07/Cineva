import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../screens/movie_detail_screen.dart';
import '../screens/series_detail_screen.dart';
import '../services/auth_service.dart';
import '../stores/bookmark_store.dart';
import '../theme/app_theme.dart';
import '../utils/routes.dart';
import '../widgets/states.dart';

class MyListScreen extends StatefulWidget {
  const MyListScreen({super.key});

  @override
  State<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BookmarkStore.instance,
      builder: (context, _) {
        final items = BookmarkStore.instance.items;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text('My List', style: AppType.h1)),
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
                Expanded(
                  child: items.isEmpty
                      ? const EmptyState(
                          title: 'Nothing here',
                          message:
                              'Movies and series you save will appear here.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.lg,
                            right: AppSpacing.lg,
                            bottom: AppSpacing.xxxl,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _row(item, index);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String get _accountInitial {
    final name = AuthService.instance.displayName.trim();
    return name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
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

  Widget _row(BookmarkItem item, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index % 5) * 60),
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
          child: Row(
            children: [
              Hero(
                tag: 'poster-${item.id}',
                child: CachedNetworkImage(
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
                  Icons.delete_outline,
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
