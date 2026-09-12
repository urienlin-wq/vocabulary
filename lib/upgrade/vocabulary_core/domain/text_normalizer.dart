class TextNormalizer {
  const TextNormalizer._();

  static String english(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('，', ',')
        .replaceAll('；', ';');
  }

  static String chinese(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[，,；;、。.]'), '');
  }

  static List<String> splitMeanings(String value) {
    return value
        .split(RegExp(r'[；;\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
