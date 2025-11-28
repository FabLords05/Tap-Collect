import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('grove_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // We create a table to store the User's session
    await db.execute('''
      CREATE TABLE user_session (
        email TEXT PRIMARY KEY,
        data TEXT  -- We will store the whole JSON object here
      )
    ''');
  }

  // 1. Save User Locally (Put in Lunchbox)
  Future<void> cacheUser(Map<String, dynamic> userJson) async {
    final db = await instance.database;
    final email = userJson['email'];
    
    // We store the whole JSON string so we don't have to make columns for everything
    await db.insert(
      'user_session',
      {'email': email, 'data': jsonEncode(userJson)},
      conflictAlgorithm: ConflictAlgorithm.replace, // Overwrite if exists
    );
  }

  // 2. Get User Locally (Eat from Lunchbox)
  Future<Map<String, dynamic>?> getCachedUser(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'user_session',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return jsonDecode(maps.first['data'] as String);
    }
    return null;
  }
  
  // 3. Clear (Logout)
  Future<void> clearCache() async {
    final db = await instance.database;
    await db.delete('user_session');
  }
}