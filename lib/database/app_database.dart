import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/download_item.dart';

/// Wraps the local SQLite database used to persist download/history
/// metadata. Handles creation, migration and basic error recovery.
class AppDatabase {
  AppDatabase._internal();
  static final AppDatabase instance = AppDatabase._internal();

  static const String _dbName = 'all_video_downloader.db';
  static const int _dbVersion = 1;
  static const String tableDownloads = 'downloads';

  Database? _db;

  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    try {
      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $tableDownloads (
              id TEXT PRIMARY KEY,
              url TEXT NOT NULL,
              downloadUrl TEXT,
              filename TEXT NOT NULL,
              localPath TEXT,
              thumbnailPath TEXT,
              fileSizeBytes INTEGER,
              downloadedBytes INTEGER,
              durationMs INTEGER,
              title TEXT,
              status TEXT NOT NULL,
              createdAt INTEGER NOT NULL,
              completedAt INTEGER
            )
          ''');
        },
      );
    } catch (e) {
      // If the database is corrupted or fails to open, delete and recreate.
      try {
        await deleteDatabase(path);
      } catch (_) {
        // Ignore secondary failure; rethrow original error below.
      }
      return await openDatabase(
        path,
        version: _dbVersion,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $tableDownloads (
              id TEXT PRIMARY KEY,
              url TEXT NOT NULL,
              downloadUrl TEXT,
              filename TEXT NOT NULL,
              localPath TEXT,
              thumbnailPath TEXT,
              fileSizeBytes INTEGER,
              downloadedBytes INTEGER,
              durationMs INTEGER,
              title TEXT,
              status TEXT NOT NULL,
              createdAt INTEGER NOT NULL,
              completedAt INTEGER
            )
          ''');
        },
      );
    }
  }

  Future<void> insertOrUpdate(DownloadItem item) async {
    final db = await database;
    await db.insert(
      tableDownloads,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<DownloadItem>> getAll() async {
    final db = await database;
    final rows = await db.query(tableDownloads, orderBy: 'createdAt DESC');
    return rows.map((r) => DownloadItem.fromMap(r)).toList();
  }

  Future<DownloadItem?> getById(String id) async {
    final db = await database;
    final rows = await db.query(
      tableDownloads,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DownloadItem.fromMap(rows.first);
  }

  Future<void> delete(String id) async {
    final db = await database;
    await db.delete(tableDownloads, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await database;
    await db.delete(tableDownloads);
  }

  Future<List<DownloadItem>> search(String query) async {
    final db = await database;
    final like = '%$query%';
    final rows = await db.query(
      tableDownloads,
      where: 'filename LIKE ? OR title LIKE ? OR url LIKE ?',
      whereArgs: [like, like, like],
      orderBy: 'createdAt DESC',
    );
    return rows.map((r) => DownloadItem.fromMap(r)).toList();
  }
}
