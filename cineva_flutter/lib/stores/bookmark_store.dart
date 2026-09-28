import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkItem {
  final String id;
  final String title;
  final String posterImg;
  final String type;

  const BookmarkItem({
    required this.id,
    required this.title,
    required this.posterImg,
    required this.type,
  });

  Map<String, String> toJson() => {
        'id': id,
        'title': title,
        'posterImg': posterImg,
        'type': type,
      };

  static BookmarkItem fromJson(Map<String, dynamic> json) => BookmarkItem(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        posterImg: json['posterImg'] as String? ?? '',
        type: json['type'] as String? ?? 'movie',
      );
}

class BookmarkStore extends ChangeNotifier {
  BookmarkStore._();

  static final BookmarkStore instance = BookmarkStore._();

  static const _key = '@cineva_my_list';

  List<BookmarkItem> _items = [];
  bool _loaded = false;

  List<BookmarkItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _items = list
            .whereType<Map<String, dynamic>>()
            .map(BookmarkItem.fromJson)
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

  Future<void> add(BookmarkItem item) async {
    _items.removeWhere((e) => e.id == item.id);
    _items.insert(0, item);
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  bool isInList(String id) => _items.any((e) => e.id == id);

  Future<void> toggle(BookmarkItem item) async {
    if (isInList(item.id)) {
      await remove(item.id);
    } else {
      await add(item);
    }
  }
}