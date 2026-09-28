import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryStore {
  SearchHistoryStore._();

  static final SearchHistoryStore instance = SearchHistoryStore._();

  static const _key = '@cineva_search_history';
  static const _maxItems = 20;

  List<String> _items = [];

  List<String> get items => List.unmodifiable(_items);

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        _items = (jsonDecode(raw) as List).whereType<String>().toList();
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_items));
  }

  Future<void> add(String query) async {
    _items.removeWhere((e) => e.toLowerCase() == query.trim().toLowerCase());
    _items.insert(0, query.trim());
    if (_items.length > _maxItems) {
      _items = _items.sublist(0, _maxItems);
    }
    await _persist();
  }

  Future<void> remove(String query) async {
    _items.remove(query);
    await _persist();
  }

  Future<void> clear() async {
    _items = [];
    await _persist();
  }
}