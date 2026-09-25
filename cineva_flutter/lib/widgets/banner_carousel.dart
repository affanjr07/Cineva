import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_theme.dart';

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
  const BannerCarousel({super.key, required this.slides});

  final List<HomeSlide> slides;

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
      height: MediaQuery.of(context).size.width * 0.85,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.slides.length,
            onPageChanged: (i) => setState(() => _activeIndex = i),
            itemBuilder: (_, i) => SlideItem(
              slide: widget.slides[i],
              active: i == _activeIndex,
            ),
          ),
          if (widget.slides.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: AppSpacing.sm,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.slides.length, (i) {
                  final active = i == _activeIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs / 2),
                    width: active ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : AppColors.textMuted.withValues(alpha: 0.5),
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
  const SlideItem({super.key, required this.slide, required this.active});

  final HomeSlide slide;
  final bool active;

  @override
  State<SlideItem> createState() => _SlideItemState();
}

class _SlideItemState extends State<SlideItem> {
  VideoPlayerController? _controller;
  bool _videoFailed = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
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
      c.setVolume(0.5);
      if (widget.active && mounted) {
        setState(() {});
        await c.play();
      }
    } catch (_) {
      if (mounted) setState(() => _videoFailed = true);
    }
  }

  @override
  void didUpdateWidget(covariant SlideItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      _syncPlayback();
    }
  }

  Future<void> _syncPlayback() async {
    final c = _controller;
    if (c == null) return;
    if (widget.active) {
      try {
        await c.seekTo(Duration.zero);
        await c.play();
      } catch (_) {}
    } else {
      try {
        await c.pause();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildContent(BuildContext context) {
    final slide = widget.slide;
    final screenWidth = MediaQuery.of(context).size.width;

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
        height: screenWidth * 0.85,
        errorBuilder: (_, _, _) => _textFallback(slide),
      );
    } else {
      hero = _textFallback(slide);
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        hero,
        Container(color: AppColors.background.withValues(alpha: 0.45)),
        Positioned(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.xl,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(slide.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.h1),
                if (slide.subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: AppSpacing.md, top: AppSpacing.xs),
                    child: Text(
                      slide.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.body.copyWith(
                          color: AppColors.textSecondary),
                    ),
                  ),
                if (slide.movieId != null && slide.movieId!.isNotEmpty)
                  Material(
                    color: AppColors.primary,
                    borderRadius:
                        BorderRadius.circular(AppRadius.md),
                    child: InkWell(
                      onTap: () {
                        if (slide.type == 'series') {
                          Navigator.of(context).pushNamed(
                            '/series/${slide.movieId}',
                            arguments:
                                slide.posterImg.isEmpty
                                    ? null
                                    : slide.posterImg,
                          );
                        } else {
                          Navigator.of(context).pushNamed(
                            '/movie/${slide.movieId}',
                            arguments:
                                slide.posterImg.isEmpty
                                    ? null
                                    : slide.posterImg,
                          );
                        }
                      },
                      borderRadius:
                          BorderRadius.circular(AppRadius.md),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Text('▶ Tonton Sekarang',
                            style: AppType.button),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _textFallback(HomeSlide slide) {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(slide.title,
              style: AppType.h1, textAlign: TextAlign.center),
          if (slide.subtitle.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(slide.subtitle,
                style: AppType.body.copyWith(
                    color: AppColors.textSecondary),
                textAlign: TextAlign.center),
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