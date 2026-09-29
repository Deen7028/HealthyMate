part of 'app_database.dart';

extension AppDatabaseLifecycle on AppDatabase {
  Future<Database?> _initDatabase() async {
    if (kIsWeb) return null;

    AppDatabase.ensureInitialized();

    final dbPath = await databaseFactory.getDatabasesPath();
    final path = p.join(dbPath, AppDatabase._dbName);

    return await openDatabase(
      path,
      version: 13,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// การอัปเกรดฐานข้อมูลแบบปลอดภัย (Safe Schema Migration)
  /// ตรวจสอบและสร้างตารางหรือคอลัมน์ใหม่ที่อาจตกหล่นจากเวอร์ชันก่อนหน้า
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 1. สร้างตารางทั้งหมดที่อาจยังไม่มี (CREATE TABLE IF NOT EXISTS)
    await _onCreate(db, newVersion);

    // 2. ตรวจสอบและเพิ่มคอลัมน์ใหม่ในแต่ละตารางอย่างปลอดภัย (Safe Add Columns)
    await _safeAddColumn(
      db,
      AppDatabase.tableUsers,
      'isSynced',
      'INTEGER DEFAULT 0',
    );
    await _safeAddColumn(
      db,
      AppDatabase.tableUsers,
      'isDarkMode',
      'INTEGER DEFAULT 0',
    );
    await _safeAddColumn(
      db,
      AppDatabase.tableUsers,
      'sProfileImagePath',
      'TEXT DEFAULT ""',
    );

    await _safeAddColumn(
      db,
      AppDatabase.tableHealthRecords,
      'computedBmr',
      'REAL',
    );
    await _safeAddColumn(
      db,
      AppDatabase.tableHealthRecords,
      'activityLevelTitle',
      'TEXT',
    );
    await _safeAddColumn(
      db,
      AppDatabase.tableHealthRecords,
      'isSynced',
      'INTEGER DEFAULT 0',
    );

    await _safeAddColumn(
      db,
      AppDatabase.tableNutritionLogs,
      'isSynced',
      'INTEGER DEFAULT 0',
    );
    await _safeAddColumn(
      db,
      AppDatabase.tableNutritionLogs,
      'nProtein',
      'REAL DEFAULT 0.0',
    );
    await _safeAddColumn(
      db,
      AppDatabase.tableNutritionLogs,
      'nCarbs',
      'REAL DEFAULT 0.0',
    );
    await _safeAddColumn(
      db,
      AppDatabase.tableNutritionLogs,
      'nFat',
      'REAL DEFAULT 0.0',
    );
    await _safeAddColumn(
      db,
      AppDatabase.tableNutritionLogs,
      'sServingSize',
      'TEXT DEFAULT ""',
    );
    await _safeAddColumn(
      db,
      AppDatabase.tableNutritionLogs,
      'sImagePath',
      'TEXT DEFAULT ""',
    );

    await _safeAddColumn(
      db,
      AppDatabase.tableRoutines,
      'sLinkedWorkout',
      'TEXT DEFAULT ""',
    );
    await _safeAddColumn(db, AppDatabase.tableRoutines, 'color', 'INTEGER');
    await _safeAddColumn(db, AppDatabase.tableRoutines, 'iconData', 'INTEGER');
    await _safeAddColumn(
      db,
      AppDatabase.tableRoutines,
      'targetValue',
      'REAL DEFAULT 1.0',
    );
    await _safeAddColumn(
      db,
      AppDatabase.tableRoutines,
      'unit',
      'TEXT DEFAULT "ครั้ง"',
    );
    await _safeAddColumn(
      db,
      AppDatabase.tableRoutines,
      'isNotificationActive',
      'INTEGER DEFAULT 1',
    );

    await _safeAddColumn(
      db,
      AppDatabase.tableRoutineLogs,
      'nProgressValue',
      'REAL DEFAULT 0.0',
    );

    await _safeAddColumn(
      db,
      AppDatabase.tableWorkouts,
      'isSynced',
      'INTEGER DEFAULT 0',
    );
    await _safeAddColumn(
      db,
      AppDatabase.tableWorkouts,
      'sRoutePoints',
      'TEXT DEFAULT ""',
    );

    await _safeAddColumn(db, 'TbGoals', 'dtCreatedAt', 'TEXT');

    debugPrint(
      'AppDatabase: Schema migrated successfully from v$oldVersion to v$newVersion',
    );
  }

  /// Helper ฟังก์ชันเพื่อเพิ่ม Column ถ้ายังไม่มีในตาราง
  Future<void> _safeAddColumn(
    Database db,
    String tableName,
    String columnName,
    String columnDef,
  ) async {
    try {
      final pragma = await db.rawQuery('PRAGMA table_info($tableName)');
      final columnExists = pragma.any(
        (col) =>
            col['name']?.toString().toLowerCase() == columnName.toLowerCase(),
      );
      if (!columnExists) {
        await db.execute(
          'ALTER TABLE $tableName ADD COLUMN $columnName $columnDef',
        );
        debugPrint(
          'AppDatabase Migration: Added column $columnName to $tableName',
        );
      }
    } catch (e) {
      debugPrint(
        'AppDatabase Migration Warning: safeAddColumn $columnName on $tableName failed: $e',
      );
    }
  }

  /// สร้าง Table Schema ทั้งหมดตาม 6620310001_HealthMateDB.sql
}
