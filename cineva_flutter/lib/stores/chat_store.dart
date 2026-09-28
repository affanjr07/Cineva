import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/gemini_client.dart';

class ChatConversation {
  final String id;
  String title;
  final List<ChatMessageData> messages;
  final int createdAt;
  int updatedAt;

  ChatConversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((e) => e.toJson()).toList(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      ChatConversation(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? 'New Chat',
        messages: (json['messages'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ChatMessageData.fromJson)
            .toList(),
        createdAt: json['createdAt'] as int? ?? 0,
        updatedAt: json['updatedAt'] as int? ?? 0,
      );
}

class ChatStore extends ChangeNotifier {
  ChatStore._();

  static final ChatStore instance = ChatStore._();

  static const _key = '@cineva_chat_history';

  List<ChatConversation> _conversations = [];
  String? _currentConversationId;
  bool _loaded = false;

  List<ChatConversation> get conversations => List.unmodifiable(_conversations);

  String? get currentConversationId => _currentConversationId;

  ChatConversation? get currentConversation {
    if (_currentConversationId == null) return null;
    for (final c in _conversations) {
      if (c.id == _currentConversationId) return c;
    }
    return null;
  }

  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        _conversations = list
            .whereType<Map<String, dynamic>>()
            .map(ChatConversation.fromJson)
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
      jsonEncode(_conversations.map((e) => e.toJson()).toList()),
    );
  }

  String createConversation() {
    final id = _generateId();
    final conv = ChatConversation(
      id: id,
      title: 'New Chat',
      messages: [],
      createdAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _conversations.insert(0, conv);
    _currentConversationId = id;
    notifyListeners();
    _persist();
    return id;
  }

  void setCurrentConversation(String? id) {
    _currentConversationId = id;
    notifyListeners();
  }

  Future<void> addMessage(String conversationId, ChatMessageData message) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _conversations = _conversations.map((conv) {
      if (conv.id != conversationId) return conv;
      final messages = [...conv.messages, message];
      var title = conv.title;
      if (conv.messages.isEmpty && message.role == 'user') {
        title = message.text.length > 50
            ? '${message.text.substring(0, 50)}...'
            : message.text;
      }
      return ChatConversation(
        id: conv.id,
        title: title,
        messages: messages,
        createdAt: conv.createdAt,
        updatedAt: now,
      );
    }).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> deleteConversation(String id) async {
    _conversations = _conversations.where((c) => c.id != id).toList();
    if (_currentConversationId == id) {
      _currentConversationId = null;
    }
    notifyListeners();
    await _persist();
  }

  static String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    final rand = DateTime.now().microsecondsSinceEpoch.toString();
    return '${now}_$rand';
  }
}