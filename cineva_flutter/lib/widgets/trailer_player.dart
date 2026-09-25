import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_theme.dart';
import '../utils/trailer.dart';

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
        headers: {
          'Referer': 'https://com.cineva.cineva_flutter',
        },
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
        child: const Text(
          'Trailer tidak tersedia',
          style: AppType.body,
        ),
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
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: GestureDetector(
                      onTap: _stopPlay,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0x99000000),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child:
                            const Icon(Icons.close, color: Colors.white, size: 20),
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
                              color: Color(0xFFFF6B6B),
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
                  Container(
                    color: Colors.black.withValues(alpha: 0.35),
                  ),
                  Center(
                    child: GestureDetector(
                      onTap: _startPlay,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0000),
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 34,
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
                              color: Color(0xFFFF6B6B),
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