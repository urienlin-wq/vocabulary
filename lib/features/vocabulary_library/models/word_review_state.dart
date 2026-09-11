class WordReviewState {
  const WordReviewState({
    required this.entryId,
    this.isFavorite = false,
    this.mustReviewNext = false,
    this.timesTested = 0,
    this.timesMarkedUnfamiliar = 0,
    this.lastTestedAt,
    required this.updatedAt,
  });

  final String entryId;
  final bool isFavorite;
  final bool mustReviewNext;
  final int timesTested;
  final int timesMarkedUnfamiliar;
  final DateTime? lastTestedAt;
  final DateTime updatedAt;

  WordReviewState copyWith({
    bool? isFavorite,
    bool? mustReviewNext,
    int? timesTested,
    int? timesMarkedUnfamiliar,
    DateTime? lastTestedAt,
    DateTime? updatedAt,
  }) {
    return WordReviewState(
      entryId: entryId,
      isFavorite: isFavorite ?? this.isFavorite,
      mustReviewNext: mustReviewNext ?? this.mustReviewNext,
      timesTested: timesTested ?? this.timesTested,
      timesMarkedUnfamiliar:
          timesMarkedUnfamiliar ?? this.timesMarkedUnfamiliar,
      lastTestedAt: lastTestedAt ?? this.lastTestedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'entry_id': entryId,
        'is_favorite': isFavorite ? 1 : 0,
        'must_review_next': mustReviewNext ? 1 : 0,
        'times_tested': timesTested,
        'times_marked_unfamiliar': timesMarkedUnfamiliar,
        'last_tested_at': lastTestedAt?.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory WordReviewState.fromMap(Map<String, Object?> map) {
    return WordReviewState(
      entryId: map['entry_id']! as String,
      isFavorite: (map['is_favorite'] as int? ?? 0) == 1,
      mustReviewNext: (map['must_review_next'] as int? ?? 0) == 1,
      timesTested: (map['times_tested'] as int? ?? 0),
      timesMarkedUnfamiliar: (map['times_marked_unfamiliar'] as int? ?? 0),
      lastTestedAt: _date(map['last_tested_at']),
      updatedAt: _date(map['updated_at']) ?? DateTime.now(),
    );
  }

  static DateTime? _date(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
