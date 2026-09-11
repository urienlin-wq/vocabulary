import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/word_entry.dart';
class WordDatabase {
  WordDatabase._(); static final instance=WordDatabase._(); Database? _db;
  Future<Database> get db async=>_db??=await openDatabase(join(await getDatabasesPath(),'words.db'),version:1,onCreate:(d,v)=>d.execute('CREATE TABLE words(id INTEGER PRIMARY KEY,english TEXT NOT NULL,chinese TEXT NOT NULL)'));
  Future<List<WordEntry>> all() async=>(await db).query('words',orderBy:'id DESC').then((r)=>r.map((x)=>WordEntry.fromMap(x)).toList());
  Future<WordEntry> save(WordEntry w) async {final d=await db;if(w.id==null)return WordEntry(id:await d.insert('words',w.toMap()..remove('id')),english:w.english,chinese:w.chinese);await d.update('words',w.toMap()..remove('id'),where:'id=?',whereArgs:[w.id]);return w;}
  Future<void> remove(int id) async=>(await db).delete('words',where:'id=?',whereArgs:[id]);
}
