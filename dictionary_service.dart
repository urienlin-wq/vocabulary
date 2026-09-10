import 'dart:convert';
import 'package:http/http.dart' as http;

class DictionaryService {
  static const String _baseUrl = 'https://api.dictionaryapi.dev/api/v2/entries/en/';

  Future<List<String>> lookupPartsOfSpeech(String word) async {
    try {
      final cleanWord = word.trim().toLowerCase();
      final resp = await http.get(Uri.parse(_baseUrl + cleanWord));
      if (resp.statusCode != 200) return [];
      final data = json.decode(resp.body) as List;
      final Set<String> pos = {};
      for (final entry in data) {
        final meanings = entry['meanings'] as List?;
        if (meanings != null) {
          for (final m in meanings) {
            if (m['partOfSpeech'] != null) pos.add(m['partOfSpeech'] as String);
          }
        }
      }
      return pos.toList();
    } catch (e) {
      return [];
    }
  }

  int editDistance(String a, String b) {
    final la = a.length;
    final lb = b.length;
    final dp = List.generate(la + 1, (i) => List<int>.filled(lb + 1, 0));
    for (int i = 0; i <= la; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= lb; j++) {
      dp[0][j] = j;
    }
    for (int i = 1; i <= la; i++) {
      for (int j = 1; j <= lb; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          final options = [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]];
          int minVal = options[0];
          for (final v in options) {
            if (v < minVal) minVal = v;
          }
          dp[i][j] = 1 + minVal;
        }
      }
    }
    return dp[la][lb];
  }

  String? findClosestMatch(String ocrGuess, List<String> candidates) {
    if (candidates.isEmpty) return null;
    String? best;
    int bestDist = 999;
    for (final c in candidates) {
      final d = editDistance(ocrGuess.toLowerCase(), c.toLowerCase());
      if (d < bestDist) {
        bestDist = d;
        best = c;
      }
    }
    return best;
  }
}
