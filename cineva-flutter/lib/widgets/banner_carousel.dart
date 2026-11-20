import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../screens/movie_detail_screen.dart';
import '../screens/series_detail_screen.dart';
import '../theme/app_theme.dart';
import '../utils/routes.dart';
import 'cinema_ui.dart';

class HomeSlide {
  final String key;
  final String title;
  final String subtitle;
  final String videoAsset;
  final String posterImg;
  final String? movieId;
  final String type;

  const HomeSlide({
    required this.key,
    required this.title,
    this.subtitle = '',
    required this.videoAsset,
    this.posterImg = '',
    this.movieId,
    this.type = 'movie',
  });
}

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({
    super.key,
    required this.slides,
    this.isVisible = true,
  });

  final List<HomeSlide> slides;

  /// Banner hanya boleh memutar suara saat benar-benar terlihat di layar.
  /// Di-set false ketika di-scroll keluar, tab lain aktif, atau ada halaman
  /// detail yang menimpa banner.
  final bool isVisible;

  static double heightFor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return math.min(width * 0.98, 470);
  }

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController();
  int _activeIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: BannerCarousel.heightFor(context),
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.slides.length,
            onPageChanged: (i) => setState(() => _activeIndex = i),
            itemBuilder: (_, i) => SlideItem(
              slide: widget.slides[i],
              active: i == _activeIndex,
              playing: widget.isVisible,
            ),
          ),
          if (widget.slides.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.md,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.slides.length, (i) {
                  final active = i == _activeIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs / 2,
                    ),
                    width: active ? 22 : 6,
                    height: 5,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : AppColors.textMuted.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

class SlideItem extends StatefulWidget {
  const SlideItem({
    super.key,
    required this.slide,
    required this.active,
    this.playing = true,
  });

  final HomeSlide slide;

  /// Slide ini sedang jadi slide aktif di dalam carousel.
  final bool active;

  /// Banner keseluruhan sedang terlihat di layar.
  final bool playing;

  @override
  State<SlideItem> createState() => _SlideItemState();
}

class _SlideItemState extends State<SlideItem> with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  Timer? _overlayTimer;
  bool _videoFailed = false;
  bool _appResumed = true;
  bool _muted = true;
  bool _overlayDimmed = false;

  bool get _shouldPlay => widget.active && widget.playing && _appResumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _appResumed = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _initVideo();
    _syncOverlayTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state == AppLifecycleState.resumed;
    if (resumed == _appResumed) return;
    _appResumed = resumed;
    _syncPlayback();
    _syncOverlayTimer();
  }

  @override
  void didUpdateWidget(covariant SlideItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final playbackChanged =
        widget.active != oldWidget.active ||
        widget.playing != oldWidget.playing;
    if (widget.active && !oldWidget.active) {
      _controller?.seekTo(Duration.zero);
    }
    _syncPlayback();
    if (playbackChanged) _syncOverlayTimer();
  }

  /// Beri waktu lima detik untuk membaca judul, lalu redupkan teks supaya
  /// video promo lebih dominan. Timer hanya berjalan saat slide benar-benar
  /// terlihat dan diputar.
  void _syncOverlayTimer() {
    _overlayTimer?.cancel();
    _overlayTimer = null;

    if (!_shouldPlay) {
      if (_overlayDimmed && mounted) {
        setState(() => _overlayDimmed = false);
      }
      return;
    }

    if (_overlayDimmed && mounted) {
      setState(() => _overlayDimmed = false);
    }
    _overlayTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || !_shouldPlay) return;
      setState(() => _overlayDimmed = true);
    });
  }

  void _revealOverlay() {
    if (!_overlayDimmed) return;
    setState(() => _overlayDimmed = false);
    _syncOverlayTimer();
  }

  Future<void> _syncPlayback() async {
    final c = _controller;
    if (c == null) return;
    try {
      if (_shouldPlay) {
        await c.play();
      } else {
        await c.pause();
      }
    } catch (_) {}
  }

  Future<void> _initVideo() async {
    if (widget.slide.videoAsset.isEmpty) {
      setState(() => _videoFailed = true);
      return;
    }
    try {
      final c = VideoPlayerController.asset(widget.slide.videoAsset);
      _controller = c;
      await c.initialize();
      c.setLooping(true);
      c.setVolume(0);
      if (_shouldPlay && mounted) {
        setState(() {});
        await c.play();
      }
    } catch (_) {
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  Future<void> _toggleMute() async {
    final next = !_muted;
    setState(() => _muted = next);
    await _controller?.setVolume(next ? 0 : 0.9);
  }

  void _openTitle() {
    final id = widget.slide.movieId;
    if (id == null || id.isEmpty) return;
    if (widget.slide.type == 'series') {
      Navigator.of(context).push(
        cinevaPageRoute(
          SeriesDetailScreen(id: id, poster: widget.slide.posterImg),
        ),
      );
    } else {
      Navigator.of(context).push(
        cinevaPageRoute(
          MovieDetailScreen(id: id, poster: widget.slide.posterImg),
        ),
      );
    }
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildContent(BuildContext context) {
    final slide = widget.slide;
    final screenWidth = MediaQuery.of(context).size.width;
    final height = BannerCarousel.heightFor(context);

    Widget hero;
    if (!_videoFailed && _controller != null) {
      hero = FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: _controller!.value.size.width,
          height: _controller!.value.size.height,
          child: VideoPlayer(_controller!),
        ),
      );
    } else if (slide.posterImg.isNotEmpty) {
      hero = Image.network(
        slide.posterImg,
        fit: BoxFit.cover,
        width: screenWidth,
        height: height,
        errorBuilder: (_, _, _) => _textFallback(slide),
      );
    } else {
      hero = _textFallback(slide);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _revealOverlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          hero,
          AnimatedOpacity(
            opacity: _overlayDimmed ? 0.48 : 1,
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            child: const DecoratedBox(
              decoration: BoxDecoration(gradient: AppGradients.heroScrim),
            ),
          ),
          Positioned(
            top: AppSpacing.md,
            left: AppSpacing.lg,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x66050B14),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'FEATURED ${slide.type.toUpperCase()}',
                    style: AppType.caption.copyWith(
                      color: AppColors.text,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_videoFailed && _controller != null)
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: CinemaIconButton(
                icon: _muted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                tooltip: _muted ? 'Turn sound on' : 'Mute video',
                onPressed: _toggleMute,
                size: 42,
                iconSize: 19,
              ),
            ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xxl,
            child: AnimatedOpacity(
              opacity: _overlayDimmed ? 0.16 : 1,
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              child: IgnorePointer(
                ignoring: _overlayDimmed,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        slide.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.h1.copyWith(
                          fontSize: 34,
                          letterSpacing: -1,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 18,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      if (slide.subtitle.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          slide.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      if (slide.movieId != null && slide.movieId!.isNotEmpty)
                        FilledButton.icon(
                          onPressed: _openTitle,
                          icon: const Icon(Icons.play_arrow_rounded, size: 21),
                          label: const Text('Watch now'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            elevation: 0,
                            shadowColor: AppColors.primary.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textFallback(HomeSlide slide) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceHigh, AppColors.background],
        ),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(slide.title, style: AppType.h1, textAlign: TextAlign.center),
          if (slide.subtitle.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              slide.subtitle,
              style: AppType.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent(context);
  }
}
