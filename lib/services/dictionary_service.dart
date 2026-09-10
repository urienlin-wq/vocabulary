import 'dart:convert';
import 'package:http/http.dart' as http;

class DictionaryService {
  static const String _baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en';

  Future<Map<String, dynamic>?> lookupWord(String word) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$word'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final entry = data[0];
          final meanings = entry['meanings'] as List<dynamic>;
          if (meanings.isNotEmpty) {
            final partOfSpeech = meanings[0]['partOfSpeech'] ?? '';
            final definitions = meanings[0]['definitions'] as List<dynamic>;
            final definition = definitions.isNotEmpty
                ? definitions[0]['definition'] ?? ''
                : '';
            return {
              'partOfSpeech': partOfSpeech,
              'definition': definition,
              'phonetic': entry['phonetic'] ?? '',
            };
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isValidWord(String word) async {
    final result = await lookupWord(word);
    return result != null;
  }
}
