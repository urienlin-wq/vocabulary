import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

enum ScanCandidateType {
  word,
  phrase,
}

class ScanCandidate {
  final String text;
  final ScanCandidateType type;

  const ScanCandidate({
    required this.text,
    required this.type,
  });

  bool get isWord => type == ScanCandidateType.word;

  bool get isPhrase => type == ScanCandidateType.phrase;

  String get typeLabel => isWord ? '单词' : '短语';
}

class OCRService {
  final TextRecognizer _englishRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _chineseRecognizer =
      TextRecognizer(script: TextRecognitionScript.chinese);

  /// 保留旧方法，避免当前的 main.dart 立刻失效。
  Future<String> recognizeEnglish(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final result = await _englishRecognizer.processImage(inputImage);
    return result.text;
  }

  /// 保留中文识别能力，后续如果要扫描中文释义可使用。
  Future<String> recognizeChinese(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final result = await _chineseRecognizer.processImage(inputImage);
    return result.text;
  }

  /// 保留上一版的新方法：只返回整页中所有去重后的英文单词。
  ///
  /// 后续 main.dart 若只需要单词列表，仍然可以使用此方法。
  Future<List<String>> recognizeEnglishWords(File imageFile) async {
    final candidates = await recognizePageCandidates(imageFile);

    return candidates
        .where((candidate) => candidate.isWord)
        .map((candidate) => candidate.text)
        .toList();
  }

  /// 新方法：扫描整页，并同时返回“单词候选”和“短语候选”。
  ///
  /// 规则：
  /// - 每行中的英文词都会作为单词候选。
  /// - 一行包含2至6个英文词、且看起来不像完整句子时，
  ///   会额外作为短语候选。
  /// - 自动去掉数字、标点和乱码。
  /// - 自动去重，保留页面中首次出现的顺序。
  /// - 单词和短语分别去重；例如 look after 和 look、after 可以同时出现。
  Future<List<ScanCandidate>> recognizePageCandidates(
    File imageFile,
  ) async {
    final inputImage = InputImage.fromFile(imageFile);
    final result = await _englishRecognizer.processImage(inputImage);

    final candidates = <ScanCandidate>[];
    final seenWords = <String>{};
    final seenPhrases = <String>{};

    for (final block in result.blocks) {
      for (final line in block.lines) {
        final lineText = line.text.trim();

        if (lineText.isEmpty) continue;

        final words = _extractEnglishWords(lineText);

        if (words.isEmpty) continue;

        for (final word in words) {
          if (seenWords.add(word)) {
            candidates.add(
              ScanCandidate(
                text: word,
                type: ScanCandidateType.word,
              ),
            );
          }
        }

        if (_isPossiblePhrase(lineText, words)) {
          final phrase = words.join(' ');

          if (seenPhrases.add(phrase)) {
            candidates.add(
              ScanCandidate(
                text: phrase,
                type: ScanCandidateType.phrase,
              ),
            );
          }
        }
      }
    }

    return candidates;
  }

  /// 从OCR文字中抽取干净的英文词。
  ///
  /// 支持：
  /// - don't
  /// - it's
  /// - mother-in-law
  List<String> _extractEnglishWords(String text) {
    final matches = RegExp(
      r"[A-Za-z]+(?:['’-][A-Za-z]+)*",
    ).allMatches(text);

    final words = <String>[];

    for (final match in matches) {
      final word = (match.group(0) ?? '').toLowerCase();

      if (_isPossibleWord(word)) {
        words.add(word);
      }
    }

    return words;
  }

  bool _isPossibleWord(String word) {
    final lettersOnly = word.replaceAll(RegExp(r"['’-]"), '');

    if (lettersOnly.length < 2) return false;
    if (lettersOnly.length > 40) return false;

    return true;
  }

  /// 判断OCR的一行文字是否更像短语，而不是完整英文句子。
  bool _isPossiblePhrase(String originalLine, List<String> words) {
    if (words.length < 2 || words.length > 6) {
      return false;
    }

    if (RegExp(r'[.!?。！？]').hasMatch(originalLine)) {
      return false;
    }

    if (RegExp(r'd').hasMatch(originalLine)) {
      return false;
    }

    final lowerLine = originalLine.trim().toLowerCase();

    const sentenceStarters = {
      'i',
      'you',
      'we',
      'they',
      'he',
      'she',
      'it',
      'this',
      'that',
      'these',
      'those',
      'there',
      'here',
    };

    if (sentenceStarters.contains(words.first)) {
      return false;
    }

    if (lowerLine.endsWith(':')) {
      return false;
    }

    return true;
  }

  void dispose() {
    _englishRecognizer.close();
    _chineseRecognizer.close();
  }
}
