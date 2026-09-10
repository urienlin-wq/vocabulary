import 'dart:math';
import 'package:flutter/material.dart';
import '../models/word_entry.dart';
import '../services/db_service.dart';

class QuizE2CScreen extends StatefulWidget {
  const QuizE2CScreen({super.key});

  @override
  State<QuizE2CScreen> createState() => _QuizE2CScreenState();
}

class _QuizE2CScreenState extends State<QuizE2CScreen> {
  final DBService _db = DBService();
  List<WordEntry> _words = [];
  WordEntry? _current;
  bool _showAnswer = false;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final words = await _db.getAllWords();
    setState(() {
      _words = words;
      _pickNext();
    });
  }

  void _pickNext() {
    if (_words.isEmpty) {
      _current = null;
      return;
    }
    setState(() {
      _current = _words[_rand.nextInt(_words.length)];
      _showAnswer = false;
    });
  }

  String getPos() {
    if (_current == null) return '';
    return _current!.partOfSpeech;
  }

  String getEnglish() {
    if (_current == null) return '';
    return _current!.english;
  }

  String getChinese() {
    if (_current == null) return '';
    return _current!.chinese;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('English to Chinese'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Exit',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Center(
        child: _words.isEmpty
            ? const Text('Word bank is empty', style: TextStyle(fontSize: 18))
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      getEnglish(),
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '[' + getPos() + ']',
                      style: const TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    const SizedBox(height: 40),
                    if (_showAnswer)
                      Text(
                        getChinese(),
                        style: const TextStyle(fontSize: 32, color: Colors.indigo),
                      ),
                    const SizedBox(height: 40),
                    if (!_showAnswer)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showAnswer = true;
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          child: Text('Show Answer', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                    if (_showAnswer)
                      ElevatedButton(
                        onPressed: _pickNext,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          child: Text('Next', style: TextStyle(fontSize: 18)),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}
