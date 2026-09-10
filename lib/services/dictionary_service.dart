import 'dart:convert';

import 'package:http/http.dart' as http;

class WordCheckResult {
  final String word;
  final bool isValid;
  final String? suggestion;
  final String partOfSpeech;
  final String definition;
  final String phonetic;

  const WordCheckResult({
    required this.word,
    required this.isValid,
    this.suggestion,
    this.partOfSpeech = '',
    this.definition = '',
    this.phonetic = '',
  });

  bool get hasSuggestion =>
      suggestion != null && suggestion!.trim().isNotEmpty;
}

class DictionaryService {
  static const String _dictionaryHost = 'api.dictionaryapi.dev';
  static const String _datamuseHost = 'api.datamuse.com';

  /// 保留旧方法：输入一个英文单词，返回词典信息。
  ///
  /// 返回 null 表示词典中没有查到，或当前网络不可用。
  Future<Map<String, dynamic>?> lookupWord(String word) async {
    final normalized = _normalizeWord(word);

    if (normalized.isEmpty) return null;

    try {
      final uri = Uri.https(
        _dictionaryHost,
        '/api/v2/entries/en/$normalized',
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);

      if (data is! List || data.isEmpty) {
        return null;
      }

      final entry = data.first;

      if (entry is! Map<String, dynamic>) {
        return null;
      }

      final meanings = entry['meanings'];

      if (meanings is! List || meanings.isEmpty) {
        return null;
      }

      final firstMeaning = meanings.first;

      if (firstMeaning is! Map<String, dynamic>) {
        return null;
      }

      final definitions = firstMeaning['definitions'];
      String definition = '';

      if (definitions is List &&
          definitions.isNotEmpty &&
          definitions.first is Map<String, dynamic>) {
        definition = definitions.first['definition']?.toString() ?? '';
      }

      return {
        'word': entry['word']?.toString() ?? normalized,
        'partOfSpeech': firstMeaning['partOfSpeech']?.toString() ?? '',
        'definition': definition,
        'phonetic': entry['phonetic']?.toString() ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  /// 保留旧方法：仅判断一个单词是否存在。
  Future<bool> isValidWord(String word) async {
    final result = await lookupWord(word);
    return result != null;
  }

  /// 新方法：校验OCR候选词，并在必要时寻找拼写修正建议。
  Future<WordCheckResult> checkWord(String word) async {
    final normalized = _normalizeWord(word);

    if (normalized.isEmpty) {
      return WordCheckResult(
        word: word,
        isValid: false,
      );
    }

    final dictionaryResult = await lookupWord(normalized);

    if (dictionaryResult != null) {
      return WordCheckResult(
        word: normalized,
        isValid: true,
        partOfSpeech: dictionaryResult['partOfSpeech']?.toString() ?? '',
        definition: dictionaryResult['definition']?.toString() ?? '',
        phonetic: dictionaryResult['phonetic']?.toString() ?? '',
      );
    }

    final suggestion = await _findVerifiedSuggestion(normalized);

    return WordCheckResult(
      word: normalized,
      isValid: false,
      suggestion: suggestion,
    );
  }

  /// 为词典中不存在的词获取“拼写相近”的候选词。
  ///
  /// 为避免把不可靠候选自动当成正确单词，
  /// 每个建议还会再次通过词典API验证。
  Future<String?> _findVerifiedSuggestion(String word) async {
    if (word.length < 3) return null;

    try {
      final uri = Uri.https(
        _datamuseHost,
        '/words',
        {
          'sp': word,
          'max': '5',
        },
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 8),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);

      if (data is! List) {
        return null;
      }

      for (final item in data) {
        if (item is! Map<String, dynamic>) continue;

        final candidate = _normalizeWord(item['word']?.toString() ?? '');

        if (candidate.isEmpty || candidate == word) continue;

        final verified = await lookupWord(candidate);

        if (verified != null) {
          return candidate;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  String _normalizeWord(String word) {
    return word
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'^[^a-z]+|[^a-z]+$'), '');
  }
}
