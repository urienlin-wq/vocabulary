import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _englishRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _chineseRecognizer =
      TextRecognizer(script: TextRecognitionScript.chinese);

  /// 保留旧方法：供当前旧版 main.dart 使用。
  Future<String> recognizeEnglish(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final result = await _englishRecognizer.processImage(inputImage);
    return result.text;
  }

  /// 保留中文识别能力，后续如果需要识别中文释义时可以使用。
  Future<String> recognizeChinese(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final result = await _chineseRecognizer.processImage(inputImage);
    return result.text;
  }

  /// 新方法：识别整页图片中的所有英文候选词。
  ///
  /// 规则：
  /// - 从OCR识别到的每个文本元素中提取英文单词。
  /// - 自动移除数字、标点、乱码。
  /// - 忽略只有一个字母的片段。
  /// - 统一转为小写。
  /// - 自动去重，保留在图片中第一次出现的顺序。
  Future<List<String>> recognizeEnglishWords(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final result = await _englishRecognizer.processImage(inputImage);

    final words = <String>[];
    final seen = <String>{};

    for (final block in result.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final extractedWords = _extractEnglishWords(element.text);

          for (final word in extractedWords) {
            if (seen.add(word)) {
              words.add(word);
            }
          }
        }
      }
    }

    return words;
  }

  /// 从一段OCR文字中提取可作为英文单词的内容。
  List<String> _extractEnglishWords(String text) {
    final matches = RegExp(
      r"[A-Za-z]+(?:['’-][A-Za-z]+)?",
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

  /// 过滤掉明显不像要背的英文词的OCR碎片。
  bool _isPossibleWord(String word) {
    if (word.length < 2) return false;

    final lettersOnly = word.replaceAll(RegExp(r"['’-]"), '');

    if (lettersOnly.length < 2) return false;
    if (lettersOnly.length > 40) return false;

    return true;
  }

  void dispose() {
    _englishRecognizer.close();
    _chineseRecognizer.close();
  }
}
