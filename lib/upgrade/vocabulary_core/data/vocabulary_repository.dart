import '../domain/vocabulary_models.dart';

abstract class VocabularyRepository {
  Future<List<VocabularyBook>> listBooks();
  Future<VocabularyBook> createBook(String name);
  Future<VocabularyBook> renameBook(String bookId, String name);
  Future<VocabularyBook> duplicateBook(String sourceBookId, String newName);
  Future<List<VocabularyWord>> wordsInBook(String bookId, {bool includeDeleted = false});
  Future<VocabularyWord> addOrMergeWord({
    required String bookId,
    required String english,
    required PartOfSpeech partOfSpeech,
    required String chineseMeaning,
  });
  Future<List<WordSearchResult>> search({String query = '', Iterable<String>? bookIds});
  Future<void> softDeleteWords(Iterable<String> wordIds);
  Future<void> restoreWords(Iterable<String> wordIds);
  Future<void> purgeExpiredDeletedWords({Duration retention = const Duration(days: 30)});
}
