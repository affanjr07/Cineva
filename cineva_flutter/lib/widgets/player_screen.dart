import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_theme.dart';

const _lk21Referer = 'https://tv12.lk21official.cc/';
const _ndReferer = 'https://tv9.nontondrama.my/';

const _verifySrc =
    'https://videonode.de/iframe3/turbovip/vILA3I5ZutC77TsDN9uYbA';

const _adBlockJs = r'''
(function () {
  var AD_SEL = '.ad,.ads,.advert,.ad-banner,.ad-container,.banner-ad,[id*="ad-"],[id*="-ad"],[class*="ad-"],[class*="-ads"],[class*="popup"],[id*="popup"],[class*="modal-ad"],[class*="overlay-ad"],[class*="adslot"],[id*="adslot"],ins.adsbygoogle,[data-ad-slot],[data-ad-client]';
  function blockAds() {
    try {
      var list = document.querySelectorAll(AD_SEL + ' , iframe[src*="doubleclick"], iframe[src*="adservice"], iframe[src*="popads"], iframe[src*="adsterra"]');
      for (var i = 0; i < list.length; i++) {
        var e = list[i];
        try { e.remove ? e.remove() : (e.style.display = 'none'); } catch (e2) {}
      }
      var txt = /(iklan|advertisement|advertis|sponsor|share|bagikan)/i;
      var a = document.querySelectorAll('a');
      for (var j = 0; j < a.length; j++) {
        var el = a[j];
        var href = (el.href || '').toLowerCase();
        if (/doubleclick\.net|googlesyndication|popads|adsterra|propellerads|adf\.ly|bit\.ly|shrink|redirect/i.test(href)) {
          try { el.setAttribute('href', 'javascript:void(0)'); el.addEventListener('click', function(ev){ ev.preventDefault(); ev.stopPropagation(); }, true); } catch (e3) {}
        }
      }
    } catch (e) {}
  }
  try {
    if (window.open) { window.open = function () { return null; }; }
  } catch (e) {}
  try {
    document.addEventListener('click', function (ev) {
      var t = ev.target;
      if (!t || !t.closest) return;
      var c = t.closest('a, [onclick]');
      if (!c) return;
      var href = ((c.href) || (c.getAttribute && c.getAttribute('onclick')) || '').toLowerCase();
      if (/(doubleclick|googlesyndication|popads|adsterra|propellerads|adf\.ly|bit\.ly|shrink|redirect|target.?=_blank)/i.test(href)) {
        ev.preventDefault(); ev.stopPropagation();
      }
    }, true);
  } catch (e) {}
  blockAds();
  setInterval(blockAds, 1200);
})();
true;
''';

const _playerCss = r'''
(function () {
  var css = [
    'html,body{margin:0!important;padding:0!important;background:#000!important;overflow:hidden!important;height:100%!important}',
    'body > *{max-width:100%!important}',
    'header,footer,nav,aside,.header,.footer,.sidebar,.nav,.menu,.ads,.advert,[class*="banner"],[id*="banner"],[class*="ad-"],[id*="-ads"],[class*="promo"]{display:none!important}',
    'video{display:block!important;width:100vw!important;height:100vh!important;object-fit:contain!important;background:#000!important;position:fixed!important;inset:0!important;z-index:9999!important}',
    '#player,#embed,#video_player,.player,.video-player,[id*="player"]{width:100vw!important;height:100vh!important;max-width:100vw!important;max-height:100vh!important;position:fixed!important;inset:0!important;z-index:9998!important;margin:0!important}',
    '.jw-wrapper,.mejs-container{width:100vw!important;height:100vh!important;max-width:100vw!important;background:#000!important}',
    '[class*="cinema-toggl"],.btn-toggle-expand,.btn-toggle-collapse,.cinema-toggle-expand,.cinema-toggle-collapse,.scroll-btn,[class*="scroll-btn"],.btn-secondary.btn-small,[id*="expand"]{display:none!important}'
  ].join('');
  var st = document.createElement('style');
  st.textContent = css;
  (document.head || document.documentElement).appendChild(st);

  function sendSrc(u) {
    if (!u) return;
    try {
      if (window.ReactNativeWebView) window.ReactNativeWebView.postMessage('SRC::' + u);
    } catch (e) {}
  }
  try {
    var _origFetch = window.fetch;
    window.fetch = function (input) {
      try {
        var u = (typeof input === 'string') ? input : (input && input.url);
        if (u && /\.(m3u8|mp4)([?#].*)?$/i.test(u)) sendSrc(u);
      } catch (e) {}
      return _origFetch.apply(this, arguments);
    };
    var _origOpen = XMLHttpRequest.prototype.open;
    XMLHttpRequest.prototype.open = function (method, url) {
      try { if (url && /\.(m3u8|mp4)([?#].*)?$/i.test(url)) sendSrc(url); } catch (e) {}
      return _origOpen.apply(this, arguments);
    };
  } catch (e) {}
  setInterval(function () {
    try {
      var v = document.querySelector('video');
      if (v) {
        var cs = v.currentSrc || v.src || '';
        if (cs && /\.(m3u8|mp4)([?#].*)?$/i.test(cs)) sendSrc(cs);
      }
    } catch (e) {}
  }, 2000);
})();
true;
''';

const _cutJs = r'''
(function(){
  function cut(){
    var doc = document;
    var f = doc.querySelector('iframe[src*="videonode"], iframe[src*="iframe3"], iframe[src*="turbovip"], iframe[src*="hydrax"], #player iframe, iframe[src*="player"]');
    var v = doc.querySelector('video');
    var target = f || v;
    if(!target) return;
    target.style.position='fixed';
    target.style.inset='0';
    target.style.width='100vw';
    target.style.height='100vh';
    target.style.objectFit='contain';
    target.style.background='#000';
    target.style.zIndex='999999';
    target.style.border='0';
    target.style.margin='0';
    if(v){ v.style.position='fixed'; v.style.inset='0'; v.style.width='100vw'; v.style.height='100vh'; v.style.objectFit='contain'; v.style.background='#000'; v.style.zIndex='1000000'; }
    var all = doc.querySelectorAll('*');
    for(var i=0;i<all.length;i++){
      var el = all[i];
      if(el===f||el===v) continue;
      if(f&&f.contains(el)) continue;
      if(f&&el.contains(f)) continue;
      if(v&&v.contains(el)) continue;
      if(v&&el.contains(v)) continue;
      try { el.style.display='none'; } catch(e){}
    }
  }
  cut();
  setInterval(cut, 900);
})();
true;
''';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, this.url, this.page});

  final String? url;
  final String? page;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _wentToStream = false;

  String? _current;

  @override
  void initState() {
    super.initState();
    final url = (widget.url ?? '').trim();
    final page = (widget.page ?? '').trim();
    _current = (page.isNotEmpty && url.isNotEmpty && page != url) ? page : (url.isNotEmpty ? url : page.isEmpty ? _verifySrc : page);

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (_) {},
        onPageStarted: (_) {
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
          _runCut();
          _maybeSwapToStream();
        },
        onWebResourceError: (_) {
          if (mounted) _loading = false;
        },
        onNavigationRequest: _shouldBlock,
      ));
    _controller = controller;

    final load = _current!;
    final referer = load.contains(RegExp('nontondrama\\.(my|click)'))
        ? _ndReferer
        : _lk21Referer;
    controller.loadRequest(Uri.parse(load), headers: {'Referer': referer});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.runJavaScript(_adBlockJs);
    });
  }

  NavigationDecision _shouldBlock(NavigationRequest request) {
    final u = request.url.toLowerCase();
    if (RegExp(r'^(intent:|market:|tel:|sms:|mailto:|geo:|fb:|whatsapp:|wa\.me|tg:|viber:|chrome:|about:chrome|android-app:)')
        .hasMatch(u)) {
      return NavigationDecision.prevent;
    }
    if (u.endsWith('.apk') || u.endsWith('.mobileconfig')) {
      return NavigationDecision.prevent;
    }
    final bad = RegExp(
        r'(doubleclick\.net|googlesyndication\.com|adservice\.google|googleadservices|googletagservices|googletagmanager\.com|popunder|popad|popads|(^|\.)outbrain\.com|(^|\.)taboola\.com|gooo\.so|workink\.link|soxsok|trafficjunky|propellerads|cpmstar|adsterra|adf\.ly|shrink\.me|shortlink|adpushup|adbutler|exoclick|juicyads|any\.website|mobiledl|mtcaptcha|clickserve|adform\.net|adnxs\.com|advertising\.com|amazon-adsystem\.com|pubmatic\.com|rubiconproject|openx\.net|revcontent\.com|mgid\.com|zedo\.com|admarvel|adcolony|applovin|vungle|mopub|chartboost|inmobi|unityads|adwhirl|adtechus|smartadserver|yieldmo|spotxchange|lijit|sovrn|33across|undertone|tremorvideo|teads|komoona|criteo|rhythmone|indexww|casalemedia|contextweb|rubicon|undertonenetwork|taboolasyndication|contentclick|bidvertiser|zergnet|adcash|cpy\.ee|bit\.ly|l\.short\.|rebrand\.ly|cutt\.ly|shorturl\.at|tinyurl\.com|is\.gd|ow\.ly|boost\.link|fastredir|redirect.*\.php|adclick|click\.advert|/ad\.php|/banner\.|/pop\.php)')
        .hasMatch(u);
    if (bad) return NavigationDecision.prevent;
    if (u.contains('about:blank')) return NavigationDecision.navigate;
    final ok = RegExp(
        r'(lk21official\.cc|lk21\.de|videonode\.de|nontondrama\.(my|click)|\.js|\.css|data:|blob:)')
        .hasMatch(u);
    if (request.isMainFrame && !ok) {
      if (!RegExp(r'(moovweb\.google\.cn|\.mp4|\.m3u8|\.ts\?|\.ts$|\.ts)')
          .hasMatch(u)) {
        return NavigationDecision.prevent;
      }
    }
    return NavigationDecision.navigate;
  }

  void _runCut() {
    _controller.runJavaScript(_playerCss);
    _controller.runJavaScript(_cutJs);
  }

  void _maybeSwapToStream() {
    final url = (widget.url ?? '').trim();
    final page = (widget.page ?? '').trim();
    if (page.isEmpty || url.isEmpty || page == url) return;
    if (_wentToStream) return;
    _wentToStream = true;
    final js =
        '(function(){ var t=${_quote(url)};'
        '(function(){ var f=document.querySelector(\'iframe[src*="videonode"],iframe[src*="iframe3"],iframe[src*="turbovip"],iframe[src*="hydrax"],iframe[src*="player"]\'); if(f){f.src=t;} else {var n=document.createElement(\'iframe\');n.src=t;n.setAttribute(\'allowfullscreen\',\'true\');n.setAttribute(\'allow\',\'autoplay; encrypted-media; fullscreen\');n.style.position=\'fixed\';n.style.inset=\'0\';n.style.width=\'100vw\';n.style.height=\'100vh\';n.style.border=\'0\';n.style.zIndex=\'9998\';document.body.appendChild(n);} })(); })();';
    _controller.runJavaScript(js);
  }

  String _quote(String s) {
    return "'${s.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}'";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: WebViewWidget(controller: _controller),
            ),
            if (_loading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            Positioned(
              top: AppSpacing.lg,
              left: AppSpacing.lg,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0x99000000),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      color: Colors.white, size: 26),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}