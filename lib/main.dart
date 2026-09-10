import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'models/word_entry.dart';
import 'services/db_service.dart';
import 'services/dictionary_service.dart';
import 'services/ocr_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '我的单词本',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class ScanItem {
  ScanItem({
    required this.text,
    required this.type,
    required this.existsInBook,
    this.checkResult,
    this.isSelected = false,
  });

  String text;
  final ScanCandidateType type;
  final bool existsInBook;
  WordCheckResult? checkResult;
  bool isSelected;

  bool get isWord => type == ScanCandidateType.word;

  bool get isPhrase => type == ScanCandidateType.phrase;

  String get typeLabel => isWord ? '单词' : '短语';

  bool get isVerified => isWord && (checkResult?.isValid ?? false);

  bool get hasSuggestion =>
      isWord && (checkResult?.hasSuggestion ?? false);

  String? get suggestion => checkResult?.suggestion;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DBService _db = DBService();
  final OCRService _ocr = OCRService();
  final DictionaryService _dictionary = DictionaryService();
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

    if (!mounted) return;

    setState(() {
      _words = words;
    });
  }

  Future<void> _pickAndScan(ImageSource source) async {
    final pickedImage = await _picker.pickImage(source: source);

    if (pickedImage == null) return;

    setState(() {
      _loading = true;
    });

    try {
      final candidates = await _ocr.recognizePageCandidates(
        File(pickedImage.path),
      );

      if (candidates.isEmpty) {
        _showMessage('没有识别到英文单词或短语，请拍清楚一点再试');
        return;
      }

      final existingWords = await _db.getAllEnglishWords();

      final items = candidates.map((candidate) {
        final exists = existingWords.contains(
          _db.normalizeEnglish(candidate.text),
        );

        return ScanItem(
          text: candidate.text,
          type: candidate.type,
          existsInBook: exists,
        );
      }).toList();

      await _checkScannedWords(items);

      if (!mounted) return;

      final addedCount = await Navigator.push<int>(
        context,
        MaterialPageRoute(
          builder: (_) => ScanResultPage(
            items: items,
            db: _db,
            dictionary: _dictionary,
          ),
        ),
      );

      if (addedCount != null && addedCount > 0) {
        await _loadWords();
        _showMessage('已添加 $addedCount 个单词或短语');
      }
    } catch (_) {
      _showMessage('扫描失败，请检查相机权限和网络后重试');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /// 逐个检查OCR得到的单词。
  ///
  /// 短语不强制整体查词典，因为许多常见搭配不一定能被普通单词词典返回；
  /// 它们仍会展示，由用户自行选择是否保存。
  Future<void> _checkScannedWords(List<ScanItem> items) async {
    final wordItems = items.where((item) {
      return item.isWord && !item.existsInBook;
    }).toList();

    const maxConcurrentChecks = 4;
    var currentIndex = 0;

    Future<void> worker() async {
      while (currentIndex < wordItems.length) {
        final item = wordItems[currentIndex];
        currentIndex++;

        item.checkResult = await _dictionary.checkWord(item.text);

        if (item.isVerified) {
          item.isSelected = true;
        }
      }
    }

    final workers = List.generate(
      maxConcurrentChecks,
      (_) => worker(),
    );

    await Future.wait(workers);
  }

  Future<void> _showManualAddDialog() async {
    final englishController = TextEditingController();
    final chineseController = TextEditingController();
    final partOfSpeechController = TextEditingController();

    WordCheckResult? checkResult;
    bool checking = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> checkSpelling() async {
              final text = englishController.text.trim();

              if (text.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('请先输入英文单词或短语')),
                );
                return;
              }

                         setDialogState(() {
                checking = true;
                checkResult = null;
              });

              final result = await _dictionary.checkWord(text);

              if (!dialogContext.mounted) return;

              setDialogState(() {
                checking = false;
                checkResult = result;
              });
            }

            String statusText = '';

            if (checking) {
              statusText = '正在检查拼写和词典……';
            } else if (checkResult != null && checkResult!.isValid) {
              statusText = '✓ 已在词典中验证';
            } else if (checkResult != null && checkResult!.hasSuggestion) {
              statusText = '建议改为：${checkResult!.suggestion}';
            } else if (checkResult != null) {
              statusText = '未在词典中验证，仍可直接保存';
            }

            return AlertDialog(
              title: const Text('添加单词 / 短语'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: englishController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: '英文单词或短语 *',
                        hintText: '例如：vocabulary 或 look after',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: partOfSpeechController,
                      decoration: const InputDecoration(
                        labelText: '词性（可不填）',
                        hintText: '例如：noun、verb、phrase',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: chineseController,
                      decoration: const InputDecoration(
                        labelText: '中文释义（可不填）',
                        hintText: '例如：词汇；词汇量',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: checking ? null : checkSpelling,
                          icon: const Icon(Icons.spellcheck),
                          label: const Text('检查拼写'),
                        ),
                      ],
                    ),
                    if (statusText.isNotEmpty) ...[
                      const SizedBox(height: 10),
                                            Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: checkResult?.isValid == true
                                ? Colors.green
                                : Colors.orange.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    if (checkResult?.hasSuggestion == true) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            englishController.text =
                                checkResult!.suggestion!;
                            setDialogState(() {
                              checkResult = null;
                            });
                          },
                          child: Text(
                            '采用建议：${checkResult!.suggestion}',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    if (englishController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('英文单词或短语不能为空')),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true) {
      final english = englishController.text.trim();

      final alreadyExists = await _db.wordExists(english);

      if (alreadyExists) {
        _showMessage('“$english”已经在单词本中');
      } else {
        await _db.insertWord(
          WordEntry(
            english: english,
            chinese: chineseController.text.trim(),
            partOfSpeech: partOfSpeechController.text.trim(),
            createdAt: DateTime.now(),
          ),
        );

        await _loadWords();
        _showMessage('已添加：$english');
      }
    }

    englishController.dispose();
    chineseController.dispose();
    partOfSpeechController.dispose();
  }

  Future<void> _deleteWord(WordEntry entry) async {
    if (entry.id == null) return;

    await _db.deleteWord(entry.id!);
    await _loadWords();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('我的单词本 (${_words.length})'),
      ),
            body: _loading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在识别并校验整页内容……'),
                ],
              ),
            )
          : _words.isEmpty
              ? const Center(
                  child: Text('还没有单词，点击右下角添加'),
                )
              : ListView.builder(
                  itemCount: _words.length,
                  itemBuilder: (context, index) {
                    final word = _words[index];

                    final subtitleParts = <String>[
                      if (word.partOfSpeech.trim().isNotEmpty)
                        word.partOfSpeech.trim(),
                      if (word.chinese.trim().isNotEmpty) word.chinese.trim(),
                    ];

                    return ListTile(
                      title: Text(word.english),
                      subtitle: subtitleParts.isEmpty
                          ? const Text('未填写中文释义')
                          : Text(subtitleParts.join(' · ')),
                      trailing: IconButton(
                        tooltip: '删除',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteWord(word),
                      ),
                    );
                  },
                ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'manual',
            tooltip: '手动添加',
            onPressed: _showManualAddDialog,
            child: const Icon(Icons.edit),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'gallery',
            tooltip: '从相册扫描',
            onPressed: () => _pickAndScan(ImageSource.gallery),
            child: const Icon(Icons.photo_library),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            heroTag: 'camera',
            tooltip: '拍照扫描',
            onPressed: () => _pickAndScan(ImageSource.camera),
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }
}

class ScanResultPage extends StatefulWidget {
  const ScanResultPage({
    super.key,
    required this.items,
    required this.db,
    required this.dictionary,
  });

  final List<ScanItem> items;
  final DBService db;
  final DictionaryService dictionary;

  @override
  State<ScanResultPage> createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  bool _saving = false;

  int get _selectedCount {
    return widget.items.where((item) => item.isSelected).length;
  }

  void _selectAll() {
    setState(() {
      for (final item in widget.items) {
        if (!item.existsInBook) {
          item.isSelected = true;
        }
      }
    });
  }

  void _clearSelection() {
    setState(() {
      for (final item in widget.items) {
        item.isSelected = false;
      }
    });
  }

  Future<void> _applySuggestion(ScanItem item) async {
    final suggestion = item.suggestion;

    if (suggestion == null || suggestion.isEmpty) return;

    setState(() {
      item.text = suggestion;
      item.isSelected = false;
      item.checkResult = null;
    });

    final result = await widget.dictionary.checkWord(suggestion);

    if (!mounted) return;

    setState(() {
      item.checkResult = result;
      item.isSelected = result.isValid;
    });
  }

  Future<void> _editItem(ScanItem item) async {
    final controller = TextEditingController(text: item.text);

    final newText = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('编辑${item.typeLabel}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: item.typeLabel,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();

                if (text.isEmpty) return;

                Navigator.pop(dialogContext, text);
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newText == null || newText.isEmpty) return;

    setState(() {
      item.text = newText;
      item.isSelected = false;
      item.checkResult = null;
    });
    if (item.isWord) {
      final result = await widget.dictionary.checkWord(newText);

      if (!mounted) return;

      setState(() {
        item.checkResult = result;
        item.isSelected = result.isValid;
      });
    }
  }

  Future<void> _saveSelected() async {
    final selectedItems = widget.items.where((item) {
      return item.isSelected && !item.existsInBook;
    }).toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先勾选要添加的单词或短语'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final entries = selectedItems.map((item) {
        final result = item.checkResult;

        return WordEntry(
          english: item.text.trim(),
          chinese: '',
          partOfSpeech: item.isPhrase
              ? 'phrase'
              : (result?.partOfSpeech ?? ''),
          createdAt: DateTime.now(),
        );
      }).toList();

      final addedCount = await widget.db.insertWords(entries);

      if (!mounted) return;

      Navigator.pop(context, addedCount);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }
    

  Color _statusColor(ScanItem item) {
    if (item.existsInBook) return Colors.grey;
    if (item.isPhrase) return Colors.blue;
    if (item.isVerified) return Colors.green;
    if (item.hasSuggestion) return Colors.orange;
    return Colors.redAccent;
  }

  String _statusText(ScanItem item) {
    if (item.existsInBook) {
      return '已在单词本中';
    }

    if (item.isPhrase) {
      return '短语：请确认后添加';
    }

    if (item.isVerified) {
      final partOfSpeech = item.checkResult?.partOfSpeech ?? '';

      if (partOfSpeech.isEmpty) {
        return '✓ 词典已验证';
      }

      return '✓ 已验证 · $partOfSpeech';
    }

    if (item.hasSuggestion) {
      return '建议：${item.suggestion}';
    }

    return '未验证，可编辑后添加';
  }

  @override
  Widget build(BuildContext context) {
    final wordCount = widget.items.where((item) => item.isWord).length;
    final phraseCount = widget.items.where((item) => item.isPhrase).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('扫描结果（已选 $_selectedCount）'),
        actions: [
          TextButton(
            onPressed: _selectAll,
            child: const Text('全选'),
          ),
          TextButton(
            onPressed: _clearSelection,
            child: const Text('取消全选'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.indigo.withOpacity(0.08),
            child: Text(
              '识别到 $wordCount 个单词、$phraseCount 个短语。'
              '绿色为已验证，橙色为有拼写建议。',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];

                return CheckboxListTile(
                  value: item.isSelected,
                  onChanged: item.existsInBook
                      ? null
                      : (value) {
                          setState(() {
                            item.isSelected = value ?? false;
                          });
                        },
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.text,
                          style: TextStyle(
                            color: item.existsInBook ? Colors.grey : null,
                            decoration: item.existsInBook
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(item).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.typeLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: _statusColor(item),
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _statusText(item),
                        style: TextStyle(
                          color: _statusColor(item),
                        ),
                      ),
                      if (item.hasSuggestion && !item.existsInBook)
                        TextButton(
                          onPressed: () => _applySuggestion(item),
                          child: Text('采用建议：${item.suggestion}'),
                        ),
                    ],
                  ),
                  secondary: IconButton(
                    tooltip: '编辑',
                    icon: const Icon(Icons.edit_outlined),
     
