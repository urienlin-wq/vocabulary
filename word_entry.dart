class WordEntry {
  final int? id;
  final String english;
  final String chinese;
  final String partOfSpeech;
  final DateTime createdAt;

  WordEntry({
    this.id,
    required this.english,
    required this.chinese,
    required this.partOfSpeech,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['english'] = english;
    map['chinese'] = chinese;
    map['partOfSpeech'] = partOfSpeech;
    map['createdAt'] = createdAt.toIso8601String();
    return map;
  }

  factory WordEntry.fromMap(Map<String, dynamic> map) {
    return WordEntry(
      id: map['id'] as int?,
      english: map['english'] as String,
      chinese: map['chinese'] as String,
      partOfSpeech: map['partOfSpeech'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
