import 'dart:math';

import '../models/vocabulary_entry.dart';
import '../models/word_review_state.dart';

enum ReviewDirection { englishToChinese, chineseToEnglish }

class ReviewQuestion {
  const ReviewQuestion({
    required this.entry,
    required this.direction,
  });

  final VocabularyEntry entry;
  final ReviewDirection direction;

  String get prompt => direction == ReviewDirection.englishToChinese
      ? entry.english
      : entry.chinese;

  String get expectedAnswer => direction == ReviewDirection.englishToChinese
      ? entry.chinese
      : entry.english;
}

class ReviewAnswerResult {
  const ReviewAnswerResult({
    required this.isCorrect,
    required this.wasMarkedUnfamiliar,
  });

  final bool isCorrect;
  final bool wasMarkedUnfamiliar;
}

class ReviewSessionSummary {
  const ReviewSessionSummary({
    required this.total,
    required this.correct,
    required this.incorrect,
    required this.unfamiliar,
  });

  final int total;
  final int correct;
  final int incorrect;
  final int unfamiliar;

  double get accuracy => total == 0 ? 0 : correct / total;
}

abstract final class VocabularyReviewEngine {
  static ReviewQuestion? nextQuestion({
    required List<VocabularyEntry> entries,
    required Map<String, WordReviewState> states,
    required ReviewDirection direction,
    Random? random,
  }) {
    if (entries.isEmpty) return null;
    final mustReview = entries.where(
      (entry) => states[entry.id]?.mustReviewNext ?? false,
    ).toList(growable: false);
    final favorites = entries.where(
      (entry) => states[entry.id]?.isFavorite ?? false,
    ).toList(growable: false);
    final candidates = mustReview.isNotEmpty
        ? mustReview
        : favorites.isNotEmpty
            ? favorites
            : entries;
    final entry = candidates[(random ?? Random()).nextInt(candidates.length)];
    return ReviewQuestion(entry: entry, direction: direction);
  }

  static ReviewAnswerResult evaluate({
    required ReviewQuestion question,
    required String answer,
    bool markedUnfamiliar = false,
  }) {
    final isCorrect = normalize(answer) == normalize(question.expectedAnswer);
    return ReviewAnswerResult(
      isCorrect: isCorrect,
      wasMarkedUnfamiliar: markedUnfamiliar,
    );
  }

  static WordReviewState applyResult({
    required WordReviewState state,
    required ReviewAnswerResult result,
    required DateTime completedAt,
  }) {
    return state.copyWith(
      mustReviewNext: !result.isCorrect || result.wasMarkedUnfamiliar,
      timesTested: state.timesTested + 1,
      timesMarkedUnfamiliar: state.timesMarkedUnfamiliar +
          (result.wasMarkedUnfamiliar ? 1 : 0),
      lastTestedAt: completedAt,
      updatedAt: completedAt,
    );
  }

  static ReviewSessionSummary summarize(
    Iterable<ReviewAnswerResult> results,
  ) {
    final values = results.toList(growable: false);
    final correct = values.where((result) => result.isCorrect).length;
    final unfamiliar = values.where((result) => result.wasMarkedUnfamiliar).length;
    return ReviewSessionSummary(
      total: values.length,
      correct: correct,
      incorrect: values.length - correct,
      unfamiliar: unfamiliar,
    );
  }

  static String normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
