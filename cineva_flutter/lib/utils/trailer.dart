String getYoutubeId(String url) {
  final u = url.trim();
  if (u.isEmpty) return '';
  final m = RegExp(
    r'(?:youtube\.com/(?:watch\?v=|shorts/|embed/|v/)|youtu\.be/|youtube-nocookie\.com/embed/)([\w-]{6,})',
  ).firstMatch(u);
  if (m != null) return m.group(1)!;
  if (u.contains('iframe')) {
    final vm = RegExp("src=[\"']([^\"']+)[\"']").firstMatch(u);
    if (vm != null) return getYoutubeId(vm.group(1)!);
  }
  return '';
}