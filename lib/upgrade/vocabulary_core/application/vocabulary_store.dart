import '../domain/text_normalizer.dart';
import '../domain/vocabulary_models.dart';

class VocabularyStore {
  VocabularyStore({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, VocabularyBook> _books = {};
  final Map<String, VocabularyWord> _words = {};
  int _sequence = 0;

  List<VocabularyBook> get books => _books.values.where((book) => !book.isDeleted).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  List<VocabularyWord> wordsInBook(String bookId, {bool includeDeleted = false}) {
    final words = _words.values.where((word) => word.bookId == bookId && (includeDeleted || !word.isDeleted)).toList();
    words.sort((a, b) => a.english.compareTo(b.english));
    return words;
  }

  VocabularyBook createBook(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('词库名称不能为空');
    final now = _clock();
    final book = VocabularyBook(id: _nextId('book'), name: cleanName, createdAt: now, updatedAt: now);
    _books[book.id] = book;
    return book;
  }

  VocabularyBook renameBook(String bookId, String name) {
    final book = _book(bookId);
    final cleanName = name.trim();
    if (cleanName.isEmpty) throw ArgumentError('词库名称不能为空');
    final changed = book.copyWith(name: cleanName, updatedAt: _clock());
    _books[bookId] = changed;
    return changed;
  }

  VocabularyBook duplicateBook(String sourceBookId, String newName) {
    final source = _book(sourceBookId);
    final duplicate = createBook(newName);
    for (final word in wordsInBook(source.id)) {
      final now = _clock();
      final copied = VocabularyWord(
        id: _nextId('word'),
        bookId: duplicate.id,
        english: word.english,
        normalizedEnglish: word.normalizedEnglish,
        senses: word.senses.map((sense) => WordSense(id: _nextId('sense'), partOfSpeech: sense.partOfSpeech, chineseMeaning: sense.chineseMeaning)).toList(),
        createdAt: now,
        updatedAt: now,
        isRequired: word.isRequired,
      );
      _words[copied.id] = copied;
    }
    return duplicate;
  }

  VocabularyWord addOrMergeWord({
    required String bookId,
    required String english,
    required PartOfSpeech partOfSpeech,
    required String chineseMeaning,
  }) {
    _book(bookId);
    final cleanEnglish = english.trim();
    final cleanChinese = chineseMeaning.trim();
    if (cleanEnglish.isEmpty || cleanChinese.isEmpty) throw ArgumentError('英文和中文含义不能为空');
    final normalizedEnglish = TextNormalizer.english(cleanEnglish);
    final existing = wordsInBook(bookId).where((word) => word.normalizedEnglish == normalizedEnglish).cast<VocabularyWord?>().firstWhere((word) => word != null, orElse: () => null);
    if (existing == null) {
      final now = _clock();
      final created = VocabularyWord(
        id: _nextId('word'),
        bookId: bookId,
        english: cleanEnglish,
        normalizedEnglish: normalizedEnglish,
        senses: [WordSense(id: _nextId('sense'), partOfSpeech: partOfSpeech, chineseMeaning: cleanChinese)],
        createdAt: now,
        updatedAt: now,
      );
      _words[created.id] = created;
      return created;
    }
    final incoming = TextNormalizer.splitMeanings(cleanChinese);
    final updatedSenses = [...existing.senses];
    final samePosIndexes = <int>[];
    for (var index = 0; index < updatedSenses.length; index++) {
      if (updatedSenses[index].partOfSpeech == partOfSpeech) samePosIndexes.add(index);
    }
    if (samePosIndexes.isEmpty) {
      updatedSenses.add(WordSense(id: _nextId('sense'), partOfSpeech: partOfSpeech, chineseMeaning: cleanChinese));
    } else {
      final index = samePosIndexes.first;
      final original = TextNormalizer.splitMeanings(updatedSenses[index].chineseMeaning);
      final known = original.map(TextNormalizer.chinese).toSet();
      for (final meaning in incoming) {
        if (known.add(TextNormalizer.chinese(meaning))) original.add(meaning);
      }
      updatedSenses[index] = updatedSenses[index].copyWith(chineseMeaning: original.join('；'));
    }
    final merged = existing.copyWith(senses: updatedSenses, updatedAt: _clock());
    _words[merged.id] = merged;
    _touchBook(bookId);
    return merged;
  }

  VocabularyWord updateWord({
    required String wordId,
    required String english,
    required List<WordSense> senses,
  }) {
    final word = _word(wordId);
    if (english.trim().isEmpty || senses.isEmpty || senses.any((sense) => sense.chineseMeaning.trim().isEmpty)) {
      throw ArgumentError('英文、词性和中文含义不能为空');
    }
    final updated = word.copyWith(english: english.trim(), normalizedEnglish: TextNormalizer.english(english), senses: senses, updatedAt: _clock());
    _words[wordId] = updated;
    _touchBook(word.bookId);
    return updated;
  }

  void softDeleteWords(Iterable<String> wordIds) {
    final now = _clock();
    for (final id in wordIds) {
      final word = _word(id);
      _words[id] = word.copyWith(deletedAt: now, updatedAt: now);
      _touchBook(word.bookId);
    }
  }

  void restoreWords(Iterable<String> wordIds) {
    for (final id in wordIds) {
      final word = _word(id);
      _words[id] = word.copyWith(clearDeletedAt: true, updatedAt: _clock());
      _touchBook(word.bookId);
    }
  }

  void purgeExpiredDeletedWords({Duration retention = const Duration(days: 30)}) {
    final deadline = _clock().subtract(retention);
    _words.removeWhere((_, word) => word.deletedAt != null && word.deletedAt!.isBefore(deadline));
  }

  List<WordSearchResult> search({String query = '', Iterable<String>? bookIds}) {
    final normalizedEnglish = TextNormalizer.english(query);
    final normalizedChinese = TextNormalizer.chinese(query);
    final allowedBooks = bookIds?.toSet();
    final results = <WordSearchResult>[];
    for (final word in _words.values.where((word) => !word.isDeleted && (allowedBooks == null || allowedBooks.contains(word.bookId)))) {
      final book = _books[word.bookId];
      if (book == null || book.isDeleted) continue;
      final score = _searchScore(word, normalizedEnglish, normalizedChinese);
      if (query.trim().isEmpty || score > 0) results.add(WordSearchResult(word: word, book: book, score: score));
    }
    results.sort((a, b) {
      final scoreOrder = b.score.compareTo(a.score);
      if (scoreOrder != 0) return scoreOrder;
      return a.word.english.compareTo(b.word.english);
    });
    return results;
  }

  int _searchScore(VocabularyWord word, String englishQuery, String chineseQuery) {
    if (englishQuery.isNotEmpty) {
      if (word.normalizedEnglish == englishQuery) return 600;
      if (word.normalizedEnglish.startsWith(englishQuery)) return 500;
      if (word.normalizedEnglish.contains(englishQuery)) return 400;
    }
    if (chineseQuery.isNotEmpty) {
      final meanings = word.senses.map((sense) => TextNormalizer.chinese(sense.chineseMeaning));
      if (meanings.any((meaning) => meaning == chineseQuery)) return 550;
      if (meanings.any((meaning) => meaning.startsWith(chineseQuery))) return 450;
      if (meanings.any((meaning) => meaning.contains(chineseQuery))) return 350;
    }
    return 0;
  }

  VocabularyBook _book(String id) {
    final book = _books[id];
    if (book == null || book.isDeleted) throw StateError('找不到词库：$id');
    return book;
  }

  VocabularyWord _word(String id) {
    final word = _words[id];
    if (word == null) throw StateError('找不到单词：$id');
    return word;
  }

  void _touchBook(String id) {
    final book = _books[id];
    if (book != null) _books[id] = book.copyWith(updatedAt: _clock());
  }

  String _nextId(String prefix) => '$prefix-${_clock().microsecondsSinceEpoch}-${_sequence++}';
}
