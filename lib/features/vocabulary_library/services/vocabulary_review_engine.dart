import 'dart:math';

import '../models/vocabulary_entry.dart';
import '../models/word_review_state.dart';

enum ReviewMode { englishToChinese, chineseToEnglishHints }

class ReviewQuestion {
  const ReviewQuestion({required this.entry, required this.mode});

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

  bool get canRevealHint => question.supportsHints &&
      !isAnswerVisible &&
      revealedCharacters < question.answer.length;

  ReviewRevealState revealHint() {
    if (!canRevealHint) return this;
    return ReviewRevealState(
      question: question,
      revealedCharacters: revealedCharacters + 1,
    );
  }

  ReviewRevealState revealAnswer() => ReviewRevealState(
        question: question,
        revealedCharacters: question.answer.length,
        isAnswerVisible: true,
      );
}

class ReviewSession {
  const ReviewSession({required this.questions, this.currentIndex = 0});

  final List<ReviewQuestion> questions;
  final int currentIndex;

  bool get isEmpty => questions.isEmpty;
  bool get isComplete => isEmpty || currentIndex >= questions.length;
  int get total => questions.length;
  int get completed => currentIndex.clamp(0, questions.length);
  ReviewQuestion? get current => isComplete ? null : questions[currentIndex];

  ReviewSession next() {
    if (isComplete) return this;
    return ReviewSession(questions: questions, currentIndex: currentIndex + 1);
  }
}

abstract final class VocabularyReviewEngine {
  static ReviewSession createSession({
    required List<VocabularyEntry> entries,
    required Map<String, WordReviewState> states,
    required ReviewMode mode,
    required int requestedCount,
    Random? random,
  }) {
    final generator = random ?? Random();
    final mustReview = <VocabularyEntry>[];
    final favorites = <VocabularyEntry>[];
    final regular = <VocabularyEntry>[];
    for (final entry in entries) {
      final state = states[entry.id];
      if (state?.mustReviewNext ?? false) {
        mustReview.add(entry);
      } else if (state?.isFavorite ?? false) {
        favorites.add(entry);
      } else {
        regular.add(entry);
      }
    }
    mustReview.shuffle(generator);
    favorites.shuffle(generator);
    regular.shuffle(generator);
    final count = requestedCount.clamp(0, entries.length);
    final selected = [...mustReview, ...favorites, ...regular].take(count);
    return ReviewSession(
      questions: selected
          .map((entry) => ReviewQuestion(entry: entry, mode: mode))
          .toList(growable: false),
    );
  }

  static ReviewRevealState start(ReviewQuestion question) {
    return ReviewRevealState(question: question);
  }
}
