// ส่วนนี้อธิบายบทบาทของไฟล์: ฐานข้อมูลภายในเครื่องและ DAO สำหรับใช้งานร่วมกันทั้งโปรเจกต์ (app database lifecycle)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'app_database.dart';

extension AppDatabaseLifecycle on AppDatabase {
  Future<Database?> _initDatabase() async {
    // เว็บไม่เปิด SQLite ผ่านเส้นทางนี้ ส่วนแพลตฟอร์มอื่นเปิดฐานข้อมูลตาม path ของเครื่อง
    if (kIsWeb) return null;

    AppDatabase.ensureInitialized();

    final dbPath = await databaseFactory.getDatabasesPath();
    final path = p.join(dbPath, AppDatabase._dbName);

    return await openDatabase(
      path,
      version: 14,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// การอัปเกรดฐานข้อมูลแบบปลอดภัย (Safe Schema Migration)
  /// ตรวจสอบและสร้างตารางหรือคอลัมน์ใหม่ที่อาจตกหล่นจากเวอร์ชันก่อนหน้า
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // สร้างโครงสร้างที่ขาดก่อน แล้วค่อยเติมคอลัมน์ที่เพิ่มในรุ่นใหม่
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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS TbWorkoutCategories (
        nCategoryId INTEGER PRIMARY KEY AUTOINCREMENT,
        sCategoryId TEXT NOT NULL UNIQUE,
        sTitle TEXT NOT NULL,
        sSubtitle TEXT,
        sIconName TEXT,
        nIconCodePoint INTEGER,
        nMetValue REAL DEFAULT 1.00,
        isMoving INTEGER DEFAULT 0,
        dtCreatedAt TEXT DEFAULT CURRENT_TIMESTAMP
      );
    ''');

    await db.execute('''
      INSERT OR IGNORE INTO TbWorkoutCategories 
        (nCategoryId, sCategoryId, sTitle, sSubtitle, sIconName, nIconCodePoint, nMetValue, isMoving) 
      VALUES
        (1, 'running', 'วิ่ง (Running)', 'ติดตามเส้นทาง GPS และความเร็ว', 'directions_run', 57904, 8.50, 1),
        (2, 'walking', 'เดิน (Walking)', 'ออกกำลังกายเบาๆ เผาผลาญไขมัน', 'directions_walk', 57906, 3.80, 1),
        (3, 'cycling', 'ปั่นจักรยาน (Cycling)', 'บันทึกระยะทางและความเร็วรอบขา', 'directions_bike', 57903, 7.50, 1),
        (4, 'meditation', 'ทำสมาธิ (Meditation)', 'ฝึกสติ ผ่อนคลายความเครียด และฟื้นฟูจิตใจ', 'self_improvement', 58718, 1.50, 0),
        (5, 'yoga', 'โยคะ (Yoga)', 'ยืดเหยียดกล้ามเนื้อ เสริมความยืดหยุ่นและสมดุล', 'spa', 58732, 3.00, 0);
    ''');

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
      // อ่าน metadata ของตารางก่อน เพื่อไม่ให้ ALTER TABLE ซ้ำกับคอลัมน์เดิม
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
