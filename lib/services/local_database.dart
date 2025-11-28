import 'dart:async';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Simple local SQLite database wrapper for Grove Rewards.
/// Provides basic tables and CRUD helpers for users, businesses and transactions.
class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();

  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('grove_rewards.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, fileName);
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Users table: store small user snapshot including activated business ids as JSON
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT,
        activated_business_ids TEXT
      )
    ''');

    // Businesses table
    await db.execute('''
      CREATE TABLE businesses(
        id TEXT PRIMARY KEY,
        name TEXT,
        meta TEXT
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        userId TEXT,
        businessId TEXT,
        amount REAL,
        ts INTEGER
      )
    ''');
  }

  // --- Users ---
  Future<void> insertUser(Map<String, Object?> user) async {
    final db = await database;
    await db.insert('users', user,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, Object?>?> getUser(String id) async {
    final db = await database;
    final res = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty) return null;
    return res.first;
  }

  Future<void> deleteUser(String id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // --- Businesses ---
  Future<void> upsertBusiness(Map<String, Object?> business) async {
    final db = await database;
    await db.insert('businesses', business,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, Object?>>> getBusinesses() async {
    final db = await database;
    return db.query('businesses');
  }

  // --- Transactions ---
  Future<void> insertTransaction(Map<String, Object?> tx) async {
    final db = await database;
    await db.insert('transactions', tx,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, Object?>>> getTransactionsForUser(
      String userId) async {
    final db = await database;
    return db.query('transactions',
        where: 'userId = ?', whereArgs: [userId], orderBy: 'ts DESC');
  }

  Future close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
