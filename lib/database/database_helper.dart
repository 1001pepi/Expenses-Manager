import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/expense.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Cache for categories and accounts
  List<Category>? _cachedCategories;
  List<Account>? _cachedAccounts;

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
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

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

    await db.execute('''
      CREATE TABLE budgets (
        id $idType,
        accountId $intType,
        categoryId $intType,
        amount $realType,
        startDate $textType,
        endDate $textType,
        tags $textType,
        comment TEXT,
        createdAt $textType,
        FOREIGN KEY (accountId) REFERENCES accounts (id),
        FOREIGN KEY (categoryId) REFERENCES categories (id),
        UNIQUE(accountId, categoryId, startDate, endDate)
      )
    ''');

    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_budgets_unique ON budgets (accountId, categoryId, startDate, endDate)',
    );

    await db.execute('''
      CREATE TABLE expenses (
        id $idType,
        accountId $intType,
        categoryId $intType,
        amount $realType,
        date $textType,
        tags $textType,
        comment TEXT,
        photo1Path TEXT,
        photo2Path TEXT,
        createdAt $textType,
        FOREIGN KEY (accountId) REFERENCES accounts (id),
        FOREIGN KEY (categoryId) REFERENCES categories (id)
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

    if (oldVersion < 3) {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const realType = 'REAL NOT NULL';
      const intType = 'INTEGER NOT NULL';
      const textType = 'TEXT NOT NULL';

      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets (
          id $idType,
          accountId $intType,
          categoryId $intType,
          amount $realType,
          startDate $textType,
          endDate $textType,
          tags $textType,
          comment TEXT,
          createdAt $textType,
          FOREIGN KEY (accountId) REFERENCES accounts (id),
          FOREIGN KEY (categoryId) REFERENCES categories (id)
        )
      ''');
    }

    if (oldVersion < 5) {
      await db.transaction((txn) async {
        await txn.execute('''
          DELETE FROM budgets
          WHERE rowid NOT IN (
            SELECT MIN(rowid)
            FROM budgets
            GROUP BY accountId, categoryId, startDate, endDate
          )
        ''');

        await txn.execute(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_budgets_unique ON budgets (accountId, categoryId, startDate, endDate)',
        );
      });
    }

    if (oldVersion < 4) {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const realType = 'REAL NOT NULL';
      const intType = 'INTEGER NOT NULL';
      const textType = 'TEXT NOT NULL';

      await db.execute('''
        CREATE TABLE IF NOT EXISTS expenses (
          id $idType,
          accountId $intType,
          categoryId $intType,
          amount $realType,
          date $textType,
          tags $textType,
          comment TEXT,
          photo1Path TEXT,
          photo2Path TEXT,
          createdAt $textType,
          FOREIGN KEY (accountId) REFERENCES accounts (id),
          FOREIGN KEY (categoryId) REFERENCES categories (id)
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
    // Invalidate cache
    _cachedAccounts = null;
    return account.copyWith(id: id);
  }

  // Get all accounts (with caching)
  Future<List<Account>> getAllAccounts({bool forceRefresh = false}) async {
    if (_cachedAccounts != null && !forceRefresh) {
      return _cachedAccounts!;
    }

    final db = await database;
    final result = await db.query('accounts', orderBy: 'name ASC');
    _cachedAccounts = result.map((map) => Account.fromMap(map)).toList();
    return _cachedAccounts!;
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
    final result = await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
    // Invalidate cache
    _cachedAccounts = null;
    return result;
  }

  // Delete an account
  Future<int> deleteAccount(int id) async {
    final db = await database;
    final result = await db.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
    // Invalidate cache
    _cachedAccounts = null;
    return result;
  }

  // Create a category
  Future<Category> createCategory(Category category) async {
    final db = await database;
    final id = await db.insert('categories', category.toMap());
    // Invalidate cache
    _cachedCategories = null;
    return category.copyWith(id: id);
  }

  // Get all categories (with caching)
  Future<List<Category>> getAllCategories({bool forceRefresh = false}) async {
    if (_cachedCategories != null && !forceRefresh) {
      return _cachedCategories!;
    }

    final db = await database;
    final result = await db.query('categories', orderBy: 'name ASC');
    _cachedCategories = result.map((map) => Category.fromMap(map)).toList();
    return _cachedCategories!;
  }

  // Update a category
  Future<int> updateCategory(Category category) async {
    final db = await database;
    final result = await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
    // Invalidate cache
    _cachedCategories = null;
    return result;
  }

  // Delete a category
  Future<int> deleteCategory(int id) async {
    final db = await database;
    final result = await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
    // Invalidate cache
    _cachedCategories = null;
    return result;
  }

  // Create a budget
  Future<int> createBudget(dynamic budget) async {
    final db = await database;
    return await db.insert('budgets', budget.toMap());
  }

  // Get all budgets
  Future<List<dynamic>> getAllBudgets() async {
    final db = await database;
    final result = await db.query('budgets', orderBy: 'createdAt DESC');
    return result;
  }

  // Get budgets by account
  Future<List<dynamic>> getBudgetsByAccount(int accountId) async {
    final db = await database;
    final result = await db.query(
      'budgets',
      where: 'accountId = ?',
      whereArgs: [accountId],
      orderBy: 'createdAt DESC',
    );
    return result;
  }

  // Get budgets by category
  Future<List<dynamic>> getBudgetsByCategory(int categoryId) async {
    final db = await database;
    final result = await db.query(
      'budgets',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      orderBy: 'createdAt DESC',
    );
    return result;
  }

  // Update a budget
  Future<int> updateBudget(dynamic budget) async {
    final db = await database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  // Delete a budget
  Future<int> deleteBudget(int id) async {
    final db = await database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // Create an expense
  Future<Expense> createExpense(Expense expense) async {
    final db = await database;
    final id = await db.insert('expenses', expense.toMap());
    return expense.copyWith(id: id);
  }

  // Get all expenses
  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  // Get expenses by account
  Future<List<Expense>> getExpensesByAccount(int accountId) async {
    final db = await database;
    final result = await db.query(
      'expenses',
      where: 'accountId = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC',
    );
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  // Get expenses by category
  Future<List<Expense>> getExpensesByCategory(int categoryId) async {
    final db = await database;
    final result = await db.query(
      'expenses',
      where: 'categoryId = ?',
      whereArgs: [categoryId],
      orderBy: 'date DESC',
    );
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  // Get expenses by date range
  Future<List<Expense>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final result = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC',
    );
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  // Get expenses by account and date range
  Future<List<Expense>> getExpensesByAccountAndDateRange(
    int accountId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final result = await db.query(
      'expenses',
      where: 'accountId = ? AND date >= ? AND date <= ?',
      whereArgs: [
        accountId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date DESC',
    );
    return result.map((map) => Expense.fromMap(map)).toList();
  }

  // Update an expense
  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // Delete an expense
  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // Close the database
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
