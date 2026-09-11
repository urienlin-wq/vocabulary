enum VocabularyEntryType { word, phrase }

enum VocabularyEntrySource { manual, scan, topicSearch }

class VocabularyEntry {
  const VocabularyEntry({
    required this.id,
    required this.libraryId,
    required this.english,
    required this.chinese,
    required this.type,
    this.source = VocabularyEntrySource.manual,
    this.topicTags = const [],
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String libraryId;
  final String english;
  final String chinese;
  final VocabularyEntryType type;
  final VocabularyEntrySource source;
  final List<String> topicTags;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPhrase => type == VocabularyEntryType.phrase;

  VocabularyEntry copyWith({
    String? libraryId,
    String? english,
    String? chinese,
    VocabularyEntryType? type,
    VocabularyEntrySource? source,
    List<String>? topicTags,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? updatedAt,
  }) {
    return VocabularyEntry(
      id: id,
      libraryId: libraryId ?? this.libraryId,
      english: english ?? this.english,
      chinese: chinese ?? this.chinese,
      type: type ?? this.type,
      source: source ?? this.source,
      topicTags: topicTags ?? this.topicTags,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'library_id': libraryId,
        'english': english,
        'chinese': chinese,
        'entry_type': type.name,
        'source': source.name,
        'topic_tags': topicTags.join('|'),
        'is_deleted': isDeleted ? 1 : 0,
        'deleted_at': deletedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory VocabularyEntry.fromMap(Map<String, Object?> map) {
    return VocabularyEntry(
      id: map['id']! as String,
      libraryId: map['library_id']! as String,
      english: map['english']! as String,
      chinese: map['chinese']! as String,
      type: VocabularyEntryType.values.byName(
        (map['entry_type'] as String?) ?? VocabularyEntryType.word.name,
      ),
      source: VocabularyEntrySource.values.byName(
        (map['source'] as String?) ?? VocabularyEntrySource.manual.name,
      ),
      topicTags: ((map['topic_tags'] as String?) ?? '')
          .split('|')
          .where((tag) => tag.isNotEmpty)
          .toList(growable: false),
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      deletedAt: _date(map['deleted_at']),
      createdAt: _date(map['created_at']) ?? DateTime.now(),
      updatedAt: _date(map['updated_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
