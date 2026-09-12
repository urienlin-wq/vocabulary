abstract final class VocabularySearchMatcher {
  static String normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool matches({
    required String query,
    required String english,
    required String chinese,
    Iterable<String> tags = const [],
  }) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) return true;

    return normalize(english).contains(normalizedQuery) ||
        normalize(chinese).contains(normalizedQuery) ||
        tags.any((tag) => normalize(tag).contains(normalizedQuery));
  }

  static int score({
    required String query,
    required String english,
    required String chinese,
    Iterable<String> tags = const [],
  }) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) return 0;

    final normalizedEnglish = normalize(english);
    final normalizedChinese = normalize(chinese);
    if (normalizedEnglish == normalizedQuery) return 100;
    if (normalizedChinese == normalizedQuery) return 90;
    if (normalizedEnglish.startsWith(normalizedQuery)) return 80;
    if (normalizedChinese.startsWith(normalizedQuery)) return 70;
    if (normalizedEnglish.contains(normalizedQuery)) return 60;
    if (normalizedChinese.contains(normalizedQuery)) return 50;
    if (tags.any((tag) => normalize(tag).contains(normalizedQuery))) return 40;
    return 0;
  }
}
