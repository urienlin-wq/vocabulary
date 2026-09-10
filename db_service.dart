import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
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
      version: 1,
      onCreate: (db, version) async {
        final createSql = 'CREATE TABLE words('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'english TEXT NOT NULL, '
            'chinese TEXT NOT NULL, '
            'partOfSpeech TEXT NOT NULL, '
            'createdAt TEXT NOT NULL)';
        await db.execute(createSql);
      },
    );
  }

  Future<int> insertWord(WordEntry word) async {
    final db = await database;
    return await db.insert('words', word.toMap());
  }

  Future<List<WordEntry>> getAllWords() async {
    final db = await database;
    final maps = await db.query('words', orderBy: 'createdAt DESC');
    return maps.map((m) => WordEntry.fromMap(m)).toList();
  }

  Future<int> deleteWord(int id) async {
    final db = await database;
    return await db.delete('words', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countWords() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM words');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
