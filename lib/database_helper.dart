import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager {
  static final ValueNotifier<Color> appColor = ValueNotifier(const Color(0xFF1E40AF));

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final colorVal = prefs.getInt('theme_color');
    if (colorVal != null) {
      appColor.value = Color(colorVal);
    }
  }

  static Future<void> setTheme(Color color) async {
    appColor.value = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_color', color.value);
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('account_manager_v5.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        identifier TEXT NOT NULL,
        password TEXT NOT NULL,
        a2f INTEGER NOT NULL,
        secret_key TEXT,
        created_at TEXT,
        updated_at TEXT,
        custom_icon_path TEXT,
        avatar_path TEXT,
        dob TEXT,
        account_year TEXT,
        tags TEXT
      )
    ''');
  }

  Future<int> insertAccount(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('accounts', row);
  }

  Future<int> updateAccount(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update('accounts', row, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> fetchAccounts({String query = '', String sortOption = 'terbaru'}) async {
    try {
      final db = await instance.database;
      String orderBy = 'updated_at DESC';

      if (sortOption == 'terlama') {
        orderBy = 'updated_at ASC';
      } else if (sortOption == 'a-z') {
        orderBy = 'name COLLATE NOCASE ASC';
      }

      if (query.isEmpty) {
        return await db.query('accounts', orderBy: orderBy);
      } else {
        return await db.query(
          'accounts',
          where: 'name LIKE ? OR identifier LIKE ? OR tags LIKE ?',
          whereArgs: ['%$query%', '%$query%', '%$query%'],
          orderBy: orderBy,
        );
      }
    } catch (e) {
      debugPrint('ERROR fetching accounts: $e');
      return [];
    }
  }

  Future<int> deleteAccount(int id) async {
    final db = await instance.database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }
}
