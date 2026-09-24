import 'dart:convert';

import 'package:http/http.dart' as http;

class ChatMessageData {
  final String role;
  final String text;

  const ChatMessageData({required this.role, required this.text});

  Map<String, dynamic> toJson() => {'role': role, 'text': text};

  factory ChatMessageData.fromJson(Map<String, dynamic> json) =>
      ChatMessageData(
        role: json['role'] as String? ?? 'model',
        text: json['text'] as String? ?? '',
      );
}

class GeminiClient {
  GeminiClient();

  static const _model = String.fromEnvironment('GEMINI_MODEL');
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  static final _movieKeywords = RegExp(
    r'(film|movie|series|drama|sinema|nonton|tonton|watch|episode|season|'
    r'trailer|judul|genre|actor|aktris|aktor|pemeran|cerita|alur|ending|'
    r'rekomendasi|recommend|horror|action|komedi|romantis|thriller|'
    r'animasi|kartun|anime|korea|drakor|hollywood|marvel|dc|spiderman|'
    r'studio|sinopsis|kualitas|hd|subtitle|sub|premier|rilis|tayang|'
    r'oscar|box\s+office|piala)', 
    caseSensitive: false,
  );

  static const _offTopicReply =
      '🎬 Halo! Aku Cineva AI — asisten khusus rekomendasi film dan series. '
      'Aku hanya bisa bantu seputar film, series, drama, atau rekomendasi tontonan. '
      'Kamu bisa tanya seperti: "Rekomendasi film action", "Film Korea terbaik", '
      'atau "Aku lupa judul film..." 😊';

  static bool isMovieRelatedQuery(String text) {
    final t = text.toLowerCase();
    if (_movieKeywords.hasMatch(t)) return true;
    if (t.length <= 60 && (t.contains('?') || t.contains('lupa'))) return true;
    return false;
  }

  static String get offTopicReply => _offTopicReply;

  static String get _modelName =>
      _model.isEmpty ? 'gemini-3.5-flash-lite' : _model;

  static String get _key => _apiKey;

  static const _systemPrompt =
      'Kamu adalah Cineva AI, asisten film cerdas di aplikasi Cineva — aplikasi katalog film dan series Indonesia.\n'
      '\n'
      'TUGASMU:\n'
      '1. Merekomendasikan film/series yang MUNGKIN tersedia di katalog Cineva (film populer, mainstream, Hollywood, Korea, Jepang, Indonesia, dll).\n'
      '2. Membantu pengguna menemukan film yang mereka lupa judulnya dengan pertanyaan lanjutan.\n'
      '\n'
      'ATURAN:\n'
      '- Jawab dalam Bahasa Indonesia yang santai dan ramah.\n'
      '- JANGAN gunakan simbol bintang (**bold**) atau tanda pagar (#). Tuliskan judul film hanya dengan huruf kapital di awal kata.\n'
      '- Gunakan emoji singkat (🎬 ⭐ 🍿) secukupnya untuk membuat respons menarik.\n'
      '- Jika pengguna lupa judul, tanya detail yang diingat (genre, aktor, adegan, tahun) lalu bantu tebak.\n'
      '- Jangan mengarang — jika tidak yakin, sarankan film serupa yang kamu tahu.\n'
      '- Max 5 rekomendasi per respons. Setiap rekomendasi: judul + alasan singkat dalam 1 baris.\n'
      '- Jawab ringkas dan cepat (max 150 kata).';

  static Map<String, dynamic> _buildPayload(List<ChatMessageData> messages) {
    return {
      'contents': messages
          .map((m) => {
                'role': m.role == 'user' ? 'user' : 'model',
                'parts': [
                  {'text': m.text},
                ],
              })
          .toList(),
      'systemInstruction': {
        'parts': [
          {'text': _systemPrompt},
        ],
      },
      'generationConfig': {
        'temperature': 0.8,
        'topP': 0.95,
        'maxOutputTokens': 600,
      },
    };
  }

  static Future<String> sendChatMessage(List<ChatMessageData> messages) async {
    if (_key.isEmpty) {
      throw Exception(
        'Gemini API key not configured. Add --dart-define=GEMINI_API_KEY=...',
      );
    }

    final url =
        'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent?key=$_key';

    final res = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(_buildPayload(messages)),
        )
        .timeout(const Duration(seconds: 90));

    if (res.statusCode != 200) {
      throw Exception('AI request failed: ${res.statusCode}');
    }

    final data = jsonDecode(res.body);
    final text =
        data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

    if (text == null || text.isEmpty) {
      throw Exception('AI returned empty response.');
    }

    return _stripMarkdown(text);
  }

  static String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^>\s?', multiLine: true), '')
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        .trim();
  }

  static Future<List<String>> getRecommendedMovieTitles(
    String context,
  ) async {
    const prompt =
        'Pengguna pernah menonton / menyimpan ini di daftar mereka: "{{CONTEXT}}".\n'
        '\n'
        'Buat 8 rekomendasi yang SANGAT berkaitan dengan film yang sudah ditonton, urutan prioritas:\n'
        '1. Sekuel/prequel/bagian lanjutan dari film yang sama.\n'
        '2. Film dalam universe/alur yang sama.\n'
        '3. Film dengan genre & nuansa serupa.\n'
        '\n'
        'Jangan menyarankan film yang SUDAH ADA di daftar tontonan pengguna. '
        'Pastikan semua judul adalah film/series mainstream yang populer dan mudah ditemukan.\n'
        '\n'
        'PENTING: Balas HANYA dengan judul-judul, satu judul per baris, tanpa nomor, tanpa bintang, '
        'tanpa deskripsi, tanpa teks lain. Contoh:\n'
        'Spider-Man 2\n'
        'Spider-Man 3\n'
        'The Avengers\n'
        'Iron Man\n'
        'Captain America: The Winter Soldier';
    final message = ChatMessageData(
      role: 'user',
      text: prompt.replaceAll('{{CONTEXT}}', context),
    );
    final reply = await sendChatMessage([message]);
    return reply
        .split('\n')
        .map((l) => l.trim().replaceAll(RegExp(r'^[\d.\-•\s]+'), ''))
        .where((l) => l.length > 1)
        .take(8)
        .toList();
  }
}