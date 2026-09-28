  import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WatchHistoryItem {
  final String id;
  final String title;
  final String posterImg;
  final String type;
  final int season;
  final int episode;
  final int watchedAt;

  const WatchHistoryItem({
    required this.id,
    required this.title,
    required this.posterImg,
    required this.type,
    this.season = 0,
    this.episode = 0,
    this.watchedAt = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'posterImg': posterImg,
        'type': type,
        'season': season,
        'episode': episode,
        'watchedAt': watchedAt,
      };

  static WatchHistoryItem fromJson(Map<String, dynamic> json) =>
      WatchHistoryItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        posterImg: json['posterImg'] as String? ?? '',
        type: json['type'] as String? ?? 'movie',
        season: json['season'] as int? ?? 0,
        episode: json['episode'] as int? ?? 0,
        watchedAt: json['watchedAt'] as int? ?? 0,
      );
}

class WatchHistoryStore extends ChangeNotifier {
  WatchHistoryStore._();

  static final WatchHistoryStore instance = WatchHistoryStore._();

  static const _key = '@cineva_watch_history';

  List<WatchHistoryItem> _items = [];
  bool _loaded = false;

  List<WatchHistoryItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _items = list
            .whereType<Map<String, dynamic>>()
            .map(WatchHistoryItem.fromJson)
            .toList();
      }
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> addItem(WatchHistoryItem item) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _items.removeWhere((e) => e.id == item.id);
    _items.insert(
      0,
      WatchHistoryItem(
        id: item.id,
        title: item.title,
        posterImg: item.posterImg,
        type: item.type,
        season: item.season,
        episode: item.episode,
        watchedAt: now,
      ),
    );
    if (_items.length > 50) {
      _items = _items.take(50).toList();
    }
    notifyListeners();
    await _persist();
  }

  Future<void> removeItem(String id) async {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }
}