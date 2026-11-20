import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_theme.dart';
import '../utils/trailer.dart';
import 'cinema_ui.dart';

class TrailerPlayer extends StatefulWidget {
  const TrailerPlayer({super.key, required this.url});

  final String url;

  @override
  State<TrailerPlayer> createState() => _TrailerPlayerState();
}

class _TrailerPlayerState extends State<TrailerPlayer> {
  WebViewController? _controller;
  bool _playing = false;

  String get _videoId => getYoutubeId(widget.url);

  String get _watchUrl => 'https://www.youtube.com/watch?v=$_videoId';

  String get _thumbUrl => 'https://i.ytimg.com/vi/$_videoId/hqdefault.jpg';

  String get _embedUrl =>
      'https://www.youtube.com/embed/$_videoId?autoplay=1&playsinline=1&rel=0';

  void _startPlay() {
    if (_videoId.isEmpty) return;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setUserAgent(
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      )
      ..loadRequest(
        Uri.parse(_embedUrl),
        headers: {'Referer': 'https://com.cineva.cineva_flutter'},
      );
    setState(() => _playing = true);
  }

  void _stopPlay() {
    _controller = null;
    setState(() => _playing = false);
  }

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoId = _videoId;
    if (videoId.isEmpty) {
      final failCard = Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        alignment: Alignment.center,
        child: const Text('Trailer tidak tersedia', style: AppType.body),
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AspectRatio(aspectRatio: 16 / 9, child: failCard),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: _playing
            ? Stack(
                fit: StackFit.expand,
                children: [
                  WebViewWidget(controller: _controller!),
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: CinemaIconButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Close trailer',
                      onPressed: _stopPlay,
                      size: 42,
                      iconSize: 19,
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.sm,
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Diputar di YouTube (HD) — kembali otomatis',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => launchUrl(
                            Uri.parse(_watchUrl),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: const Text(
                            'Buka di YouTube',
                            style: TextStyle(
                              color: AppColors.primarySoft,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: _thumbUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Container(
                      color: Colors.black,
                      alignment: Alignment.center,
                      child: const Text(
                        'Trailer tidak tersedia',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  Container(color: Colors.black.withValues(alpha: 0.35)),
                  Center(
                    child: Semantics(
                      button: true,
                      label: 'Play trailer',
                      child: GestureDetector(
                        onTap: _startPlay,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: AppGradients.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primarySoft.withValues(
                                alpha: 0.32,
                              ),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 22,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.text,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.sm,
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Putar langsung di sini',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => launchUrl(
                            Uri.parse(_watchUrl),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: const Text(
                            'Buka di YouTube',
                            style: TextStyle(
                              color: AppColors.primarySoft,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
