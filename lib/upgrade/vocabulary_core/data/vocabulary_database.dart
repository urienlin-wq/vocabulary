import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class VocabularyDatabase {
  VocabularyDatabase._();

  static const _databaseName = 'word_memorizer.db';
  static const _databaseVersion = 1;
  static final VocabularyDatabase instance = VocabularyDatabase._();

  Database? _database;

  Future<Database> get database async {
    final opened = _database;
    if (opened != null) return opened;
    final databasesPath = await getDatabasesPath();
    final databasePath = path.join(databasesPath, _databaseName);
    final created = await openDatabase(
      databasePath,
      version: _databaseVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createSchema,
    );
    _database = created;
    return created;
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vocabulary_books (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE vocabulary_words (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        english TEXT NOT NULL,
        normalized_english TEXT NOT NULL,
        is_required INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        FOREIGN KEY(book_id) REFERENCES vocabulary_books(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE word_senses (
        id TEXT PRIMARY KEY,
        word_id TEXT NOT NULL,
        part_of_speech TEXT NOT NULL,
        chinese_meaning TEXT NOT NULL,
        FOREIGN KEY(word_id) REFERENCES vocabulary_words(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_books_deleted ON vocabulary_books(deleted_at)');
    await db.execute('CREATE INDEX idx_words_book_deleted ON vocabulary_words(book_id, deleted_at)');
    await db.execute('CREATE INDEX idx_words_normalized_english ON vocabulary_words(normalized_english)');
    await db.execute('CREATE INDEX idx_senses_word ON word_senses(word_id)');
  }

  Future<T> transaction<T>(Future<T> Function(Transaction transaction) action) async {
    final db = await database;
    return db.transaction(action);
  }

  Future<void> close() async {
    final opened = _database;
    if (opened == null) return;
    await opened.close();
    _database = null;
  }

  Future<void> deleteAllDataForDevelopment() async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.delete('word_senses');
      await transaction.delete('vocabulary_words');
      await transaction.delete('vocabulary_books');
    });
  }
}
