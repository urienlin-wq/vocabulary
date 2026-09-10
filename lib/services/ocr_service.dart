import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final TextRecognizer _chineseRecognizer = TextRecognizer(script: TextRecognitionScript.chinese);

  Future<String> recognizeEnglish(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText result = await _recognizer.processImage(inputImage);
    return result.text;
  }

  Future<String> recognizeChinese(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final RecognizedText result = await _chineseRecognizer.processImage(inputImage);
    return result.text;
  }

  void dispose() {
    _recognizer.close();
    _chineseRecognizer.close();
  }
}
