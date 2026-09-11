import 'dart:math';
import 'package:flutter/material.dart';

class VocabularyReviewPage extends StatefulWidget {
  const VocabularyReviewPage({super.key, required this.words, this.count = 10});
  final List<Map<String, String>> words;
  final int count;
  @override
  State<VocabularyReviewPage> createState() => _VocabularyReviewPageState();
}

class _VocabularyReviewPageState extends State<VocabularyReviewPage> {
  late final List<Map<String, String>> _items;
  int _index = 0, _hint = 0;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _items = [...widget.words]..shuffle(Random());
    _items.removeRange(min(widget.count, _items.length), _items.length);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const Scaffold(body: Center(child: Text('没有可测试的单词')));
    final word = _items[_index];
    final englishFirst = _index.isEven;
    final prompt = englishFirst ? word['english']! : word['chinese']!;
    final answer = englishFirst ? word['chinese']! : word['english']!;
    final visible = englishFirst || _showAnswer ? answer : answer.substring(0, min(_hint, answer.length));
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${_index + 1}/${_items.length}', textAlign: TextAlign.right),
          const Spacer(),
          Text(prompt, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 24),
          Text(visible, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          const Spacer(),
          if (!englishFirst && !_showAnswer) OutlinedButton(onPressed: () => setState(() => _hint = min(_hint + 1, answer.length)), child: const Text('提示')),
          OutlinedButton(onPressed: () => setState(() => _showAnswer = true), child: const Text('显示答案')),
          FilledButton(onPressed: _index + 1 == _items.length ? () => Navigator.pop(context) : () => setState(() { _index++; _hint = 0; _showAnswer = false; }), child: Text(_index + 1 == _items.length ? '完成' : '下一题')),
        ]),
      ),
    );
  }
}