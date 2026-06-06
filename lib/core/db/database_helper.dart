import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final instance = DatabaseHelper._();
  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final p = join(await getDatabasesPath(), 'job_offer_us.db');
    return openDatabase(
      p,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE history ADD COLUMN signing_bonus REAL NOT NULL DEFAULT 0');
        }
        if (oldVersion < 3) {
          await db.execute(
              'ALTER TABLE history ADD COLUMN comparison_json TEXT');
        }
        if (oldVersion < 4) {
          await db.execute(
              'ALTER TABLE history ADD COLUMN is_pinned INTEGER NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE history ADD COLUMN input_hash TEXT');
          await db.execute('ALTER TABLE history ADD COLUMN pin_label TEXT');
          await db.execute(
              'ALTER TABLE history ADD COLUMN pin_order INTEGER NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE history ADD COLUMN l1_json TEXT');
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        job_title TEXT NOT NULL,
        company TEXT NOT NULL,
        location TEXT NOT NULL,
        salary REAL NOT NULL,
        bonus REAL NOT NULL DEFAULT 0,
        benefits REAL NOT NULL DEFAULT 0,
        stock_options REAL NOT NULL DEFAULT 0,
        relocation REAL NOT NULL DEFAULT 0,
        pto INTEGER NOT NULL DEFAULT 0,
        signing_bonus REAL NOT NULL DEFAULT 0,
        net_salary REAL NOT NULL,
        monthly_net REAL NOT NULL,
        tax_rate REAL NOT NULL,
        created_at TEXT NOT NULL,
        comparison_json TEXT,
        is_pinned INTEGER NOT NULL DEFAULT 0,
        input_hash TEXT,
        pin_label TEXT,
        pin_order INTEGER NOT NULL DEFAULT 0,
        l1_json TEXT
      )
    ''');
  }

  /// Insert a row. Returns the auto-generated row id.
  Future<int> insertHistory(Map<String, dynamic> row) async {
    final db = await database;
    return db.insert('history', row);
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final db = await database;
    return db.query('history',
        orderBy: 'is_pinned DESC, pin_order DESC, created_at DESC');
  }

  Future<Map<String, dynamic>?> getHistoryByHash(String hash) async {
    final db = await database;
    final rows = await db.query('history',
        where: 'input_hash = ?', whereArgs: [hash], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> updateHistoryEntry(int id, Map<String, dynamic> values) async {
    final db = await database;
    return db.update('history', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countHistory({bool? isPinned}) async {
    final db = await database;
    final String sql;
    if (isPinned == null) {
      sql = 'SELECT COUNT(*) FROM history';
    } else {
      sql =
          'SELECT COUNT(*) FROM history WHERE is_pinned = ${isPinned ? 1 : 0}';
    }
    final result = await db.rawQuery(sql);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getOldestAutoSaves(int limit) async {
    final db = await database;
    return db.query('history',
        where: 'is_pinned = 0', orderBy: 'created_at ASC', limit: limit);
  }

  Future<List<Map<String, dynamic>>> getOldestPinnedEntries(int limit) async {
    final db = await database;
    return db.query('history',
        where: 'is_pinned = 1',
        orderBy: 'pin_order ASC, created_at ASC',
        limit: limit);
  }

  Future<void> deleteHistory(int id) async {
    final db = await database;
    await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteOldestHistory() async {
    final db = await database;
    await db.rawDelete(
      'DELETE FROM history WHERE id = (SELECT id FROM history WHERE is_pinned = 0 ORDER BY created_at ASC LIMIT 1)',
    );
  }

  Future<void> clearHistory() async {
    final db = await database;
    await db.delete('history');
  }

  Future<Map<String, dynamic>?> getHistoryById(int id) async {
    final db = await database;
    final result = await db.query('history', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }
}
