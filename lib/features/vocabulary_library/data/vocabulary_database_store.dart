import 'package:sqflite/sqflite.dart';

import 'vocabulary_database_schema.dart';

class VocabularyDatabaseStore {
  const VocabularyDatabaseStore(this._database);

  final Future<Database> _database;

  Future<List<Map<String, Object?>>> listLibraries({
    bool includeDeleted = false,
  }) async {
    final db = await _database;
    return db.query(
      VocabularyDatabaseSchema.librariesTable,
      where: includeDeleted ? null : 'is_deleted = 0',
      orderBy: 'is_system_library DESC, updated_at DESC',
    );
  }

  Future<void> saveLibrary(Map<String, Object?> library) async {
    final db = await _database;
    await db.insert(
      VocabularyDatabaseSchema.librariesTable,
      library,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> softDeleteLibrary(String libraryId, DateTime deletedAt) async {
    final db = await _database;
    final timestamp = deletedAt.toIso8601String();
    await db.transaction((txn) async {
      await txn.update(VocabularyDatabaseSchema.librariesTable, {'is_deleted': 1, 'deleted_at': timestamp, 'updated_at': timestamp}, where: 'id = ?', whereArgs: [libraryId]);
      await txn.update(VocabularyDatabaseSchema.entriesTable, {'is_deleted': 1, 'deleted_at': timestamp, 'updated_at': timestamp}, where: 'library_id = ?', whereArgs: [libraryId]);
    });
  }

  Future<void> restoreLibrary(String libraryId, DateTime restoredAt) async {
    final db = await _database;
    final timestamp = restoredAt.toIso8601String();
    await db.transaction((txn) async {
      await txn.update(VocabularyDatabaseSchema.librariesTable, {'is_deleted': 0, 'deleted_at': null, 'updated_at': timestamp}, where: 'id = ?', whereArgs: [libraryId]);
      await txn.update(VocabularyDatabaseSchema.entriesTable, {'is_deleted': 0, 'deleted_at': null, 'updated_at': timestamp}, where: 'library_id = ?', whereArgs: [libraryId]);
    });
  }

  Future<List<Map<String, Object?>>> listEntries({required String libraryId, bool includeDeleted = false, String? query}) async {
    final db = await _database;
    final clauses = <String>['library_id = ?'];
    final arguments = <Object?>[libraryId];
    if (!includeDeleted) clauses.add('is_deleted = 0');
    final normalizedQuery = query?.trim();
    if (normalizedQuery != null && normalizedQuery.isNotEmpty) {
      clauses.add('(english LIKE ? COLLATE NOCASE OR chinese LIKE ? OR topic_tags LIKE ?)');
      final pattern = '%$normalizedQuery%';
      arguments.addAll([pattern, pattern, pattern]);
    }
    return db.query(VocabularyDatabaseSchema.entriesTable, where: clauses.join(' AND '), whereArgs: arguments, orderBy: 'updated_at DESC');
  }

  Future<void> saveEntry(Map<String, Object?> entry) async {
    final db = await _database;
    await db.insert(VocabularyDatabaseSchema.entriesTable, entry, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> softDeleteEntries(Iterable<String> entryIds, DateTime deletedAt) async {
    final ids = entryIds.toSet().toList();
    if (ids.isEmpty) return;
    final db = await _database;
    final placeholders = List.filled(ids.length, '?').join(', ');
    final timestamp = deletedAt.toIso8601String();
    await db.update(VocabularyDatabaseSchema.entriesTable, {'is_deleted': 1, 'deleted_at': timestamp, 'updated_at': timestamp}, where: 'id IN ($placeholders)', whereArgs: ids);
  }

  Future<void> restoreEntries(Iterable<String> entryIds, DateTime restoredAt) async {
    final ids = entryIds.toSet().toList();
    if (ids.isEmpty) return;
    final db = await _database;
    final placeholders = List.filled(ids.length, '?').join(', ');
    await db.update(VocabularyDatabaseSchema.entriesTable, {'is_deleted': 0, 'deleted_at': null, 'updated_at': restoredAt.toIso8601String()}, where: 'id IN ($placeholders)', whereArgs: ids);
  }

  Future<void> permanentlyDeleteEntries(Iterable<String> entryIds) async {
    final ids = entryIds.toSet().toList();
    if (ids.isEmpty) return;
    final db = await _database;
    final placeholders = List.filled(ids.length, '?').join(', ');
    await db.transaction((txn) async {
      await txn.delete(VocabularyDatabaseSchema.reviewStatesTable, where: 'entry_id IN ($placeholders)', whereArgs: ids);
      await txn.delete(VocabularyDatabaseSchema.entriesTable, where: 'id IN ($placeholders)', whereArgs: ids);
    });
  }

  Future<Map<String, Object?>?> findReviewState(String entryId) async {
    final db = await _database;
    final rows = await db.query(VocabularyDatabaseSchema.reviewStatesTable, where: 'entry_id = ?', whereArgs: [entryId], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> saveReviewState(Map<String, Object?> state) async {
    final db = await _database;
    await db.insert(VocabularyDatabaseSchema.reviewStatesTable, state, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
