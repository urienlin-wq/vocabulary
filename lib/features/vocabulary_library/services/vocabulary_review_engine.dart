import 'dart:math';

import '../models/vocabulary_entry.dart';
import '../models/word_review_state.dart';

enum ReviewMode { englishToChinese, chineseToEnglishHints }

class ReviewQuestion {
  const ReviewQuestion({
    required this.entry,
    required this.mode,
  });

  final VocabularyEntry entry;
  final ReviewMode mode;

  String get prompt => mode == ReviewMode.englishToChinese
      ? entry.english
      : entry.chinese;

  String get answer => mode == ReviewMode.englishToChinese
      ? entry.chinese
      : entry.english;

  bool get supportsHints => mode == ReviewMode.chineseToEnglishHints;
}

class ReviewRevealState {
  const ReviewRevealState({
    required this.question,
    this.revealedCharacters = 0,
    this.isAnswerVisible = false,
  });

  final ReviewQuestion question;
  final int revealedCharacters;
  final bool isAnswerVisible;

  String get visibleAnswer {
    if (isAnswerVisible) return question.answer;
    if (!question.supportsHints) return '';
    final length = revealedCharacters.clamp(0, question.answer.length);
    return question.answer.substring(0, length);
  }

  bool get canRevealHint =>
      question.supportsHints && !isAnswerVisible && revealedCharacters < question.answer.length;

  ReviewRevealState revealHint() {
    if (!canRevealHint) return this;
    return ReviewRevealState(
      question: question,
      revealedCharacters: revealedCharacters + 1,
    );
  }

  ReviewRevealState revealAnswer() {
    return ReviewRevealState(
      question: question,
      revealedCharacters: question.answer.length,
      isAnswerVisible: true,
    );
  }
}

abstract final class VocabularyReviewEngine {
  static ReviewQuestion? nextQuestion({
    required List<VocabularyEntry> entries,
    required Map<String, WordReviewState> states,
    required ReviewMode mode,
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
    return ReviewQuestion(entry: entry, mode: mode);
  }

  static ReviewRevealState start(ReviewQuestion question) {
    return ReviewRevealState(question: question);
  }
}
