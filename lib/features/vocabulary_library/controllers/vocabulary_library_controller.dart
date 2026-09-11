import 'package:flutter/foundation.dart';

import '../models/vocabulary_entry.dart';
import '../models/vocabulary_library.dart';
import '../models/word_review_state.dart';
import '../repositories/vocabulary_library_repository.dart';

class VocabularyLibraryController extends ChangeNotifier {
  VocabularyLibraryController(this._repository);

  final VocabularyLibraryRepository _repository;

  List<VocabularyLibrary> _libraries = const [];
  List<VocabularyEntry> _entries = const [];
  String? _selectedLibraryId;
  String _query = '';
  bool _isLoading = false;
  Object? _error;

  List<VocabularyLibrary> get libraries => _libraries;
  List<VocabularyEntry> get entries => _entries;
  String? get selectedLibraryId => _selectedLibraryId;
  String get query => _query;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  Future<void> loadLibraries({bool includeDeleted = false}) async {
    await _run(() async {
      _libraries = await _repository.getLibraries(
        includeDeleted: includeDeleted,
      );
    });
  }

  Future<void> selectLibrary(String? libraryId) async {
    _selectedLibraryId = libraryId;
    _entries = const [];
    _query = '';
    notifyListeners();
    if (libraryId != null) await loadEntries();
  }

  Future<void> loadEntries({bool includeDeleted = false}) async {
    final libraryId = _selectedLibraryId;
    if (libraryId == null) {
      _entries = const [];
      notifyListeners();
      return;
    }
    await _run(() async {
      _entries = await _repository.getEntries(
        libraryId,
        includeDeleted: includeDeleted,
        query: _query,
      );
    });
  }

  Future<void> search(String value) async {
    _query = value;
    notifyListeners();
    await loadEntries();
  }

  Future<void> saveLibrary(VocabularyLibrary library) async {
    await _run(() async {
      await _repository.saveLibrary(library);
      _libraries = await _repository.getLibraries();
    });
  }

  Future<void> saveEntry(VocabularyEntry entry) async {
    await _run(() async {
      await _repository.saveEntry(entry);
      if (entry.libraryId == _selectedLibraryId) await _reloadSelectedEntries();
    });
  }

  Future<void> deleteEntries(List<String> entryIds) async {
    await _run(() async {
      await _repository.softDeleteEntries(entryIds, DateTime.now());
      await _reloadSelectedEntries();
    });
  }

  Future<void> restoreEntries(List<String> entryIds) async {
    await _run(() async {
      await _repository.restoreEntries(entryIds, DateTime.now());
      await _reloadSelectedEntries();
    });
  }

  Future<WordReviewState> reviewStateFor(String entryId) {
    return _repository.getReviewState(entryId);
  }

  Future<void> saveReviewState(WordReviewState state) {
    return _run(() => _repository.saveReviewState(state));
  }

  Future<void> _reloadSelectedEntries() async {
    final libraryId = _selectedLibraryId;
    if (libraryId == null) return;
    _entries = await _repository.getEntries(libraryId, query: _query);
  }

  Future<void> _run(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
