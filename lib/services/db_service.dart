import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../features/vocabulary_library/data/vocabulary_database_migrator.dart';
import '../features/vocabulary_library/data/vocabulary_database_schema.dart';
import '../models/word_entry.dart';

class DBService {
  static final DBService _instance = DBService._internal();

  factory DBService() => _instance;

  DBService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'words.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createLegacyWordsTable(db);
        await VocabularyDatabaseMigrator.upgradeToVersion2(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await VocabularyDatabaseMigrator.upgradeToVersion2(db);
        }
      },
    );
  }

  Future<void> _createLegacyWordsTable(Database db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS words('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'english TEXT NOT NULL, '
      'chinese TEXT NOT NULL, '
      'partOfSpeech TEXT NOT NULL, '
      'createdAt TEXT NOT NULL'
      ')',
    );
  }

  /// 保留旧方法：手动添加一个单词时使用。
  Future<int> insertWord(WordEntry word) async {
    final db = await database;
    final id = await db.insert('words', word.toMap());
    await VocabularyDatabaseMigrator.syncLegacyWords(db);
    return id;
  }

  /// 新方法：一次保存多个已勾选单词。
  ///
  /// 自动跳过：
  /// - 英文为空的项目
  /// - 本次列表中重复的项目
  /// - 数据库中已经存在的项目
  ///
  /// 返回真正新增成功的数量。
  Future<int> insertWords(List<WordEntry> words) async {
    if (words.isEmpty) return 0;

    final db = await database;
    final existingWords = await getAllEnglishWords();
    final wordsToInsert = <WordEntry>[];
    final seenInThisBatch = <String>{};

    for (final word in words) {
      final normalized = normalizeEnglish(word.english);

      if (normalized.isEmpty) continue;
      if (existingWords.contains(normalized)) continue;
      if (!seenInThisBatch.add(normalized)) continue;

      wordsToInsert.add(word);
    }

    if (wordsToInsert.isEmpty) return 0;

    final batch = db.batch();
    for (final word in wordsToInsert) {
      batch.insert('words', word.toMap());
    }

    await batch.commit(noResult: true);
    await VocabularyDatabaseMigrator.syncLegacyWords(db);
    return wordsToInsert.length;
  }

  Future<List<WordEntry>> getAllWords() async {
    final db = await database;
    final maps = await db.query('words', orderBy: 'createdAt DESC');
    return maps.map((map) => WordEntry.fromMap(map)).toList();
  }

  /// 返回已经保存在单词本中的英文单词集合。
  ///
  /// 返回的词统一为小写，便于与OCR结果比较。
  Future<Set<String>> getAllEnglishWords() async {
    final db = await database;
    final maps = await db.query('words', columns: ['english']);

    return maps
        .map((map) => normalizeEnglish(map['english']?.toString() ?? ''))
        .where((word) => word.isNotEmpty)
        .toSet();
  }

  /// 判断单词是否已存在。
  Future<bool> wordExists(String english) async {
    final normalized = normalizeEnglish(english);
    if (normalized.isEmpty) return false;

    final words = await getAllEnglishWords();
    return words.contains(normalized);
  }

  /// 统一英文格式，比较时忽略前后空格和大小写。
  String normalizeEnglish(String english) {
    return english.trim().toLowerCase();
  }

  Future<int> deleteWord(int id) async {
    final db = await database;
    final deleted = await db.delete('words', where: 'id = ?', whereArgs: [id]);
    if (deleted > 0) {
      await db.update(
        VocabularyDatabaseSchema.entriesTable,
        {
          'is_deleted': 1,
          'deleted_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: ['legacy-$id'],
      );
    }
    return deleted;
  }

  Future<int> countWords() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM words');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
