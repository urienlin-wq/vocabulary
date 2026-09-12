class WordEntry {
  const WordEntry({
    this.id,
    required this.english,
    required this.chinese,
    this.partOfSpeech = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int? id;
  final String english;
  final String chinese;
  final String partOfSpeech;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'english': english,
        'chinese': chinese,
        'partOfSpeech': partOfSpeech,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WordEntry.fromMap(Map<String, Object?> map) {
    final createdAtValue = map['createdAt']?.toString();

    return WordEntry(
      id: map['id'] as int?,
      english: map['english'] as String,
      chinese: map['chinese'] as String,
      partOfSpeech: map['partOfSpeech']?.toString() ?? '',
      createdAt: createdAtValue == null
          ? null
          : DateTime.tryParse(createdAtValue),
    );
  }
}
