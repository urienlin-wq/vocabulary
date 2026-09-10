import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models/word_entry.dart';
import 'services/db_service.dart';
import 'services/ocr_service.dart';
import 'services/dictionary_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '单词本',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DBService _db = DBService();
  final OCRService _ocr = OCRService();
  final DictionaryService _dict = DictionaryService();
  final ImagePicker _picker = ImagePicker();

  List<WordEntry> _words = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final words = await _db.getAllWords();
    setState(() => _words = words);
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    setState(() => _loading = true);
    final file = File(picked.path);

    try {
      final rawText = await _ocr.recognizeEnglish(file);
      final candidate = rawText.trim().split(RegExp(r's+')).firstWhere(
            (w) => w.isNotEmpty,
            orElse: () => '',
          );

      if (candidate.isEmpty) {
        _showMessage('未识别到英文单词');
        return;
      }

      final lookup = await _dict.lookupWord(candidate.toLowerCase());
      if (lookup == null) {
        _showMessage('词典中未找到: $candidate');
        return;
      }

      await _showConfirmDialog(candidate, lookup);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showConfirmDialog(String english, Map<String, dynamic> lookup) async {
    final chineseController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(english),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('词性: ${lookup['partOfSpeech']}'),
            Text('英文释义: ${lookup['definition']}'),
            const SizedBox(height: 12),
            TextField(
              controller: chineseController,
              decoration: const InputDecoration(labelText: '输入中文释义'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
        ],
      ),
    );

    if (result == true) {
      final entry = WordEntry(
        english: english,
        chinese: chineseController.text.trim(),
        partOfSpeech: lookup['partOfSpeech'] ?? '',
        createdAt: DateTime.now(),
      );
      await _db.insertWord(entry);
      await _loadWords();
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _deleteWord(WordEntry entry) async {
    if (entry.id != null) {
      await _db.deleteWord(entry.id!);
      await _loadWords();
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
      appBar: AppBar(title: Text('我的单词本 (${_words.length})')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _words.isEmpty
              ? const Center(child: Text('还没有单词，点击右下角拍照添加'))
              : ListView.builder(
                  itemCount: _words.length,
                  itemBuilder: (ctx, i) {
                    final w = _words[i];
                    return ListTile(
                      title: Text(w.english),
                      subtitle: Text('${w.partOfSpeech} · ${w.chinese}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteWord(w),
                      ),
                    );
                  },
                ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'gallery',
            onPressed: () => _pickAndProcessImage(ImageSource.gallery),
            child: const Icon(Icons.photo_library),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'camera',
            onPressed: () => _pickAndProcessImage(ImageSource.camera),
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }
}
