import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> initializeDB() async {
    await _initDatabase();
  }

///////////////////////////////////////////////////////////////////////////////////////
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'university.db');
    // Initialize FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

////////////////////////////////////////////////////////////////////////////////////////
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        password TEXT,
        isAdmin INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        content TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE schedule (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        day INTEGER,
        weekType INTEGER,
        startTime TEXT,
        endTime TEXT,
        subject TEXT,
        teacher TEXT,
        room TEXT,
        type TEXT
      )
    ''');

    // Initial data for testing
    await db.insert('users', {
      'username': 'admin',
      'password': md5.convert(utf8.encode('admin')).toString(),
      'isAdmin': 1
    });
    await db.insert('users', {
      'username': 'user',
      'password': md5.convert(utf8.encode('user')).toString(),
      'isAdmin': 0
    });
  }
}
