import 'dart:async';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/download_task.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    // Use FFI for Windows desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final appDir = await getApplicationSupportDirectory();
    final dbPath = p.join(appDir.path, 'downloader_media.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE download_history (
            id TEXT PRIMARY KEY,
            url TEXT NOT NULL,
            title TEXT NOT NULL,
            thumbnail_url TEXT,
            platform TEXT,
            output_path TEXT NOT NULL,
            type TEXT NOT NULL,
            format TEXT NOT NULL,
            quality TEXT NOT NULL,
            status TEXT NOT NULL,
            progress REAL DEFAULT 0.0,
            file_size TEXT,
            duration INTEGER,
            error TEXT,
            created_at INTEGER NOT NULL,
            completed_at INTEGER
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_status ON download_history(status)
        ''');

        await db.execute('''
          CREATE INDEX idx_created_at ON download_history(created_at DESC)
        ''');
      },
    );
  }

  Future<void> insertTask(DownloadTask task) async {
    final db = await database;
    await db.insert(
      'download_history',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTask(DownloadTask task) async {
    final db = await database;
    await db.update(
      'download_history',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    final db = await database;
    await db.delete(
      'download_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<DownloadTask>> getHistory({int limit = 50, int offset = 0}) async {
    final db = await database;
    final results = await db.query(
      'download_history',
      where: 'status = ?',
      whereArgs: ['completed'],
      orderBy: 'completed_at DESC',
      limit: limit,
      offset: offset,
    );
    return results.map((row) => DownloadTask.fromMap(row)).toList();
  }

  Future<List<DownloadTask>> getAllTasks() async {
    final db = await database;
    final results = await db.query(
      'download_history',
      orderBy: 'created_at DESC',
    );
    return results.map((row) => DownloadTask.fromMap(row)).toList();
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete(
      'download_history',
      where: 'status = ?',
      whereArgs: ['completed'],
    );
  }
}
