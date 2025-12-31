import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/account.dart';
import '../models/category.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init() {
    // Initialize FFI for desktop platforms
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expenses_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE accounts (
        id $idType,
        name $textType,
        currency $textType,
        color $intType
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        iconCode $intType,
        color $intType
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      const intType = 'INTEGER NOT NULL';

      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id $idType,
          name $textType,
          iconCode $intType,
          color $intType
        )
      ''');
    }
  }

  // Ensure default account exists
  Future<void> ensureDefaultAccount() async {
    final accounts = await getAllAccounts();
    if (accounts.isEmpty) {
      await createAccount(
        Account(
          name: 'main',
          currency: 'EUR',
          color: 0xFF2196F3, // Blue color
        ),
      );
    }
  }

  // Insert an account
  Future<Account> createAccount(Account account) async {
    final db = await database;
    final id = await db.insert('accounts', account.toMap());
    return account.copyWith(id: id);
  }

  // Get all accounts
  Future<List<Account>> getAllAccounts() async {
    final db = await database;
    final result = await db.query('accounts', orderBy: 'name ASC');
    return result.map((map) => Account.fromMap(map)).toList();
  }

  // Get a single account by id
  Future<Account?> getAccount(int id) async {
    final db = await database;
    final maps = await db.query('accounts', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Account.fromMap(maps.first);
    }
    return null;
  }

  // Update an account
  Future<int> updateAccount(Account account) async {
    final db = await database;
    return db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  // Delete an account
  Future<int> deleteAccount(int id) async {
    final db = await database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // Insert a category
  Future<Category> createCategory(Category category) async {
    final db = await database;
    final id = await db.insert('categories', category.toMap());
    return category.copyWith(id: id);
  }

  // Get all categories
  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((map) => Category.fromMap(map)).toList();
  }

  // Update a category
  Future<int> updateCategory(Category category) async {
    final db = await database;
    return db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // Delete a category
  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Close the database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
