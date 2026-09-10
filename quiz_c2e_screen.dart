import 'dart:math';
import 'package:flutter/material.dart';
import '../models/word_entry.dart';
import '../services/db_service.dart';

class QuizC2EScreen extends StatefulWidget {
  const QuizC2EScreen({super.key});

  @override
  State<QuizC2EScreen> createState() => _QuizC2EScreenState();
}

class _QuizC2EScreenState extends State<QuizC2EScreen> {
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

  String firstLetter(String word) {
    if (word.isEmpty) return '';
    return word.substring(0, 1).toUpperCase();
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
        title: const Text('Chinese to English'),
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
                      getChinese(),
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '[' + getPos() + ']  First letter: ' + firstLetter(getEnglish()),
                      style: const TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    const SizedBox(height: 40),
                    if (_showAnswer)
                      Text(
                        getEnglish(),
                        style: const TextStyle(fontSize: 36, color: Colors.indigo, fontWeight: FontWeight.bold),
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
