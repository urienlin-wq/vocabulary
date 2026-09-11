import 'package:sqflite/sqflite.dart';

import '../config/default_libraries.dart';
import 'vocabulary_database_schema.dart';

abstract final class VocabularyDatabaseMigrator {
  static Future<void> upgradeToVersion2(Database db) async {
    await db.execute(VocabularyDatabaseSchema.createLibrariesTable);
    await db.execute(VocabularyDatabaseSchema.createEntriesTable);
    await db.execute(VocabularyDatabaseSchema.createReviewStatesTable);
    await db.execute(VocabularyDatabaseSchema.createActiveEntriesIndex);
    await db.execute(VocabularyDatabaseSchema.createEnglishSearchIndex);
    await _seedDefaultLibraries(db);
    await _migrateLegacyWords(db);
  }

  static Future<void> _seedDefaultLibraries(Database db) async {
    final batch = db.batch();
    for (final library in DefaultLibraries.create()) {
      batch.insert(
        VocabularyDatabaseSchema.librariesTable,
        library.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  static Future<void> _migrateLegacyWords(Database db) async {
    final existing = await db.query(
      'sqlite_master',
      columns: ['name'],
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'words'],
      limit: 1,
    );
    if (existing.isEmpty) return;

    final legacyWords = await db.query('words');
    final batch = db.batch();
    for (final word in legacyWords) {
      final legacyId = word['id'];
      final english = (word['english']?.toString() ?? '').trim();
      if (legacyId == null || english.isEmpty) continue;
      final createdAt = word['createdAt']?.toString() ??
          DateTime.now().toIso8601String();
      batch.insert(
        VocabularyDatabaseSchema.entriesTable,
        {
          'id': 'legacy-$legacyId',
          'library_id': DefaultLibraries.regularId,
          'english': english,
          'chinese': (word['chinese']?.toString() ?? '').trim(),
          'entry_type': english.contains(RegExp(r'\s')) ? 'phrase' : 'word',
          'source': 'manual',
          'topic_tags': '',
          'is_deleted': 0,
          'deleted_at': null,
          'created_at': createdAt,
          'updated_at': createdAt,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }
}
