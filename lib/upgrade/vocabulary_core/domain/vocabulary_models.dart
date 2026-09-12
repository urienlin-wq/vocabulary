enum PartOfSpeech {
  noun('n.'),
  verb('v.'),
  adjective('adj.'),
  adverb('adv.'),
  pronoun('pron.'),
  preposition('prep.'),
  conjunction('conj.'),
  interjection('interj.'),
  phrase('phr.'),
  other('其他');

  const PartOfSpeech(this.label);
  final String label;
}

class WordSense {
  const WordSense({
    required this.id,
    required this.partOfSpeech,
    required this.chineseMeaning,
  });

  final String id;
  final PartOfSpeech partOfSpeech;
  final String chineseMeaning;

  WordSense copyWith({PartOfSpeech? partOfSpeech, String? chineseMeaning}) {
    return WordSense(
      id: id,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      chineseMeaning: chineseMeaning ?? this.chineseMeaning,
    );
  }
}

class VocabularyWord {
  const VocabularyWord({
    required this.id,
    required this.bookId,
    required this.english,
    required this.normalizedEnglish,
    required this.senses,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.isRequired = false,
  });

  final String id;
  final String bookId;
  final String english;
  final String normalizedEnglish;
  final List<WordSense> senses;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isRequired;

  bool get isDeleted => deletedAt != null;

  VocabularyWord copyWith({
    String? bookId,
    String? english,
    String? normalizedEnglish,
    List<WordSense>? senses,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    bool? isRequired,
  }) {
    return VocabularyWord(
      id: id,
      bookId: bookId ?? this.bookId,
      english: english ?? this.english,
      normalizedEnglish: normalizedEnglish ?? this.normalizedEnglish,
      senses: senses ?? this.senses,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      isRequired: isRequired ?? this.isRequired,
    );
  }
}

class VocabularyBook {
  const VocabularyBook({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  VocabularyBook copyWith({
    String? name,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return VocabularyBook(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }
}

class WordSearchResult {
  const WordSearchResult({required this.word, required this.book, required this.score});

  final VocabularyWord word;
  final VocabularyBook book;
  final int score;
}
