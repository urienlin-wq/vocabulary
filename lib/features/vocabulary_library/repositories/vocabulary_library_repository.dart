import '../models/vocabulary_entry.dart';
import '../models/vocabulary_library.dart';
import '../models/word_review_state.dart';

abstract class VocabularyLibraryRepository {
  Future<List<VocabularyLibrary>> getLibraries({bool includeDeleted = false});

  Future<VocabularyLibrary?> getLibrary(String libraryId);

  Future<void> saveLibrary(VocabularyLibrary library);

  Future<void> softDeleteLibrary(String libraryId, DateTime deletedAt);

  Future<void> restoreLibrary(String libraryId, DateTime restoredAt);

  Future<List<VocabularyEntry>> getEntries(
    String libraryId, {
    bool includeDeleted = false,
    String? query,
  });

  Future<void> saveEntry(VocabularyEntry entry);

  Future<void> softDeleteEntries(List<String> entryIds, DateTime deletedAt);

  Future<void> restoreEntries(List<String> entryIds, DateTime restoredAt);

  Future<void> permanentlyDeleteEntries(List<String> entryIds);

  Future<WordReviewState> getReviewState(String entryId);

  Future<void> saveReviewState(WordReviewState state);
}
