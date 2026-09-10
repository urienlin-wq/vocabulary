import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/word_entry.dart';
import '../services/db_service.dart';
import '../services/ocr_service.dart';
import '../services/dictionary_service.dart';

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final OCRService _ocr = OCRService();
  final DictionaryService _dict = DictionaryService();
  final DBService _db = DBService();

  File? _image;
  bool _loading = false;

  final List<String> _localWordBank = [
    'abandon', 'ability', 'benefit', 'category', 'diligent', 'efficient',
    'genuine', 'hesitate', 'illustrate', 'jeopardy', 'knowledge', 'legitimate',
  ];

  List<ParsedWord> _parsedWords = [];

  List<String> splitLines(String text) {
    final splitter = LineSplitter();
    final lines = splitter.convert(text);
    final result = <String>[];
    for (final l in lines) {
      if (l.trim().isNotEmpty) {
        result.add(l.trim());
      }
    }
    return result;
  }

  Future<void> _takePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _loading = true;
      _parsedWords = [];
    });
    await _processImage(_image!);
    setState(() {
      _loading = false;
    });
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _loading = true;
      _parsedWords = [];
    });
    await _processImage(_image!);
    setState(() {
      _loading = false;
    });
  }

  Future<void> _processImage(File img) async {
    final english = await _ocr.recognizeEnglish(img);
    final chinese = await _ocr.recognizeChinese(img);

    final enLines = splitLines(english);
    final cnLines = splitLines(chinese);

    final List<ParsedWord> results = [];
    int n = enLines.length;
    if (cnLines.length > n) {
      n = cnLines.length;
    }

    for (int i = 0; i < n; i++) {
      String en = '';
      String cn = '';
      if (i < enLines.length) {
        en = enLines[i];
      }
      if (i < cnLines.length) {
        cn = cnLines[i];
      }

      bool corrected = false;
      final onlyLetters = en.replaceAll(RegExp('[^a-zA-Z]'), '');
      if (onlyLetters.length < 2) {
        final match = _dict.findClosestMatch(en, _localWordBank);
        if (match != null) {
          en = match;
          corrected = true;
        }
      }

      final pos = await _dict.lookupPartsOfSpeech(en);
      String firstPos = 'unknown';
      if (pos.isNotEmpty) {
        firstPos = pos.first;
      }

      results.add(ParsedWord(
        english: en,
        chinese: cn,
        partOfSpeech: firstPos,
        corrected: corrected,
      ));
    }

    setState(() {
      _parsedWords = results;
    });
  }

  Future<void> _saveAll() async {
    for (final w in _parsedWords) {
      if (w.english.isEmpty || w.chinese.isEmpty) continue;
      await _db.insertWord(WordEntry(
        english: w.english,
        chinese: w.chinese,
        partOfSpeech: w.partOfSpeech,
        createdAt: DateTime.now(),
      ));
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Words saved')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Word')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading) const CircularProgressIndicator(),
            if (_image != null && !_loading) Expanded(child: buildResultList()),
          ],
        ),
      ),
    );
  }

  Widget buildResultList() {
    final List<Widget> items = [];
    items.add(Image.file(_image!, height: 200));
    items.add(const SizedBox(height: 12));
    for (final w in _parsedWords) {
      items.add(buildWordCard(w));
    }
    items.add(const SizedBox(height: 12));
    if (_parsedWords.isNotEmpty) {
      items.add(
        ElevatedButton(
          onPressed: _saveAll,
          child: const Text('Save to word bank'),
        ),
      );
    }
    return ListView(children: items);
  }

  Widget buildWordCard(ParsedWord w) {
    final title = w.english + '  [' + w.partOfSpeech + ']';
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(w.chinese),
        trailing: w.corrected ? const Icon(Icons.auto_fix_high, color: Colors.orange) : null,
      ),
    );
  }
}

class ParsedWord {
  String english;
  String chinese;
  String partOfSpeech;
  bool corrected;
  ParsedWord({
    required this.english,
    required this.chinese,
    required this.partOfSpeech,
    required this.corrected,
  });
}
