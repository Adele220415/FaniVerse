import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// The SQLite-backed offline store.
///
/// The feed is cached here on every successful load, and read back when the
/// network is unavailable or Firestore errors out, so a cold start with no
/// connection still renders the last-loaded content instead of an error.
///
/// ## Web support
///
/// `sqflite` has no web implementation. This uses `sqflite_common_ffi_web`,
/// which requires two files in `web/`:
///
///   * `sqlite3.wasm`
///   * `sqflite_sw.js`
///
/// Get them from the package's own directories (see README) or run
/// `tool/setup_sqflite_web.ps1`, which copies them for you. Without those
/// files, opening the database on the web throws and the feed falls back to
/// network-only.
///
/// ## What is deliberately not cached
///
/// Only `content` documents. Auth state, interactions and notifications stay
/// network-only: a stale "you liked this" is worse than no answer, and the
/// engagement counters are already kept correct by transactions.
class LocalCache {
  LocalCache._();

  static final LocalCache instance = LocalCache._();

  /// Bumped whenever the schema changes, so an old database file is discarded
  /// rather than queried with a layout it does not have.
  static const int _version = 1;

  static const String _contentTable = 'content';

  Database? _db;
  Future<Database>? _opening;

  /// Opens (and migrates) the database. Safe to call repeatedly; the same
  /// future is reused rather than opening a second connection.
  Future<Database> get database async {
    final existing = _db;
    if (existing != null && existing.isOpen) return existing;

    return _opening ??= _open().then((db) {
      _db = db;
      return db;
    }).whenComplete(() => _opening = null);
  }

  Future<Database> _open() async {
    final dir = await _databaseDirectory();
    // On the web there is no filesystem path: the ffi_web implementation takes
    // an empty path and stores the database in IndexedDB.
    final path = dir.isEmpty ? 'faniverse_cache.db' : p.join(dir, 'faniverse_cache.db');

    if (kIsWeb) {
      // Installs the IndexedDB-backed factory. Must happen before any
      // openDatabase call on the web, and must only happen there - the native
      // sqflite plugin is not involved.
      databaseFactory = databaseFactoryFfiWeb;
    }

    return openDatabase(
      path,
      version: _version,
      onCreate: (db, version) async {
        // The whole document is stored as JSON. The feed's documents are
        // varied and evolve with the schema, so normalising them into columns
        // would mean a migration for every field the app adds.
        await db.execute('''
          CREATE TABLE $_contentTable (
            id         TEXT PRIMARY KEY,
            payload    TEXT NOT NULL,
            sort_key   REAL NOT NULL,
            cached_at  INTEGER NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_content_sort ON $_contentTable (sort_key DESC)',
        );
      },
    );
  }

  /// Web needs no path at all - `sqflite_common_ffi_web` stores the database
  /// in the browser's IndexedDB via its worker. Native uses the app-support
  /// directory.
  Future<String> _databaseDirectory() async {
    if (kIsWeb) return '';
    return _nativeDirectory();
  }

  Future<String> _nativeDirectory() async {
    final dir = await getApplicationSupportDirectory();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Overwrites the cached feed with [documents].
  ///
  /// Cached rows are deleted first so a post deleted on another device
  /// disappears from the offline view too, rather than lingering until some
  /// future write happened to touch it.
  Future<void> saveContent(List<Map<String, dynamic>> documents) async {
    if (documents.isEmpty) return;

    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;
      final batch = db.batch();

      batch.delete(_contentTable);
      for (final doc in documents) {
        final id = doc['id']?.toString();
        if (id == null || id.isEmpty) continue;

        batch.insert(_contentTable, {
          'id': id,
          'payload': jsonEncode(doc),
          // Trending-ish ordering so the offline list is not arbitrary.
          'sort_key': _sortKey(doc),
          'cached_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
    } catch (e) {
      // A cache miss must never take the feed down with it.
      _log('saveContent failed: $e');
    }
  }

  /// The cached feed, newest first. Empty when nothing has been cached yet.
  Future<List<Map<String, dynamic>>> readContent({int limit = 50}) async {
    try {
      final db = await database;
      final rows = await db.query(
        _contentTable,
        orderBy: 'sort_key DESC',
        limit: limit,
      );
      return rows
          .map((row) => jsonDecode(row['payload'] as String) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      _log('readContent failed: $e');
      return const [];
    }
  }

  /// When the cache was last written, for the "last updated" label.
  Future<DateTime?> lastCachedAt() async {
    try {
      final db = await database;
      final rows = await db.query(
        _contentTable,
        columns: ['cached_at'],
        orderBy: 'sort_key DESC',
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return DateTime.fromMillisecondsSinceEpoch(rows.first['cached_at'] as int);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final db = await database;
      await db.delete(_contentTable);
    } catch (e) {
      _log('clear failed: $e');
    }
  }

  Future<void> close() async {
    final db = _db;
    _db = null;
    await db?.close();
  }

  /// Mirrors the feed's trending score so cached ordering roughly matches the
  /// live ordering.
  static double _sortKey(Map<String, dynamic> doc) {
    double num_(String key) => (doc[key] as num?)?.toDouble() ?? 0;
    return (num_('likes') * 3) + num_('views') + (num_('comments') * 4) + (num_('saved') * 5);
  }

  static void _log(String message) {
    // ignore: avoid_print
    print('[LocalCache] $message');
  }
}
