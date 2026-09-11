import '../../../services/db_service.dart';
import '../data/vocabulary_database_store.dart';
import '../models/vocabulary_entry.dart';
import '../models/vocabulary_library.dart';
import '../models/word_review_state.dart';
import 'vocabulary_library_repository.dart';

class SqliteVocabularyLibraryRepository implements VocabularyLibraryRepository {
  SqliteVocabularyLibraryRepository({VocabularyDatabaseStore? store})
      : _store = store ?? VocabularyDatabaseStore(DBService().database);

  final VocabularyDatabaseStore _store;

  @override
  Future<List<VocabularyLibrary>> getLibraries({bool includeDeleted = false}) async {
    final rows = await _store.listLibraries(includeDeleted: includeDeleted);
    return rows.map(VocabularyLibrary.fromMap).toList(growable: false);
  }

  @override
  Future<VocabularyLibrary?> getLibrary(String libraryId) async {
    final libraries = await getLibraries(includeDeleted: true);
    for (final library in libraries) {
      if (library.id == libraryId) return library;
    }
    return null;
  }

  @override
  Future<void> saveLibrary(VocabularyLibrary library) => _store.saveLibrary(library.toMap());

  @override
  Future<void> softDeleteLibrary(String libraryId, DateTime deletedAt) => _store.softDeleteLibrary(libraryId, deletedAt);

  @override
  Future<void> restoreLibrary(String libraryId, DateTime restoredAt) => _store.restoreLibrary(libraryId, restoredAt);

  @override
  Future<List<VocabularyEntry>> getEntries(String libraryId, {bool includeDeleted = false, String? query}) async {
    final rows = await _store.listEntries(libraryId: libraryId, includeDeleted: includeDeleted, query: query);
    return rows.map(VocabularyEntry.fromMap).toList(growable: false);
  }

  @override
  Future<void> saveEntry(VocabularyEntry entry) => _store.saveEntry(entry.toMap());

  @override
  Future<void> softDeleteEntries(List<String> entryIds, DateTime deletedAt) => _store.softDeleteEntries(entryIds, deletedAt);

  @override
  Future<void> restoreEntries(List<String> entryIds, DateTime restoredAt) => _store.restoreEntries(entryIds, restoredAt);

  @override
  Future<void> permanentlyDeleteEntries(List<String> entryIds) => _store.permanentlyDeleteEntries(entryIds);

  @override
  Future<WordReviewState> getReviewState(String entryId) async {
    final row = await _store.findReviewState(entryId);
    if (row != null) return WordReviewState.fromMap(row);
    return WordReviewState(entryId: entryId, updatedAt: DateTime.now());
  }

  @override
  Future<void> saveReviewState(WordReviewState state) => _store.saveReviewState(state.toMap());
}
