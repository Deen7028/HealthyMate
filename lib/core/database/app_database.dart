import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/sync_service.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_common_ffi.dart';

part 'daos/user_dao.dart';
part 'daos/user_dao_registration.dart';
part 'daos/user_dao_session.dart';
part 'daos/user_dao_credentials.dart';
part 'daos/health_record_dao.dart';
part 'daos/workout_dao.dart';
part 'daos/routine_dao.dart';
part 'daos/routine_dao_mutations.dart';
part 'daos/routine_dao_logs.dart';
part 'daos/routine_dao_history.dart';
part 'daos/nutrition_dao.dart';
part 'daos/goal_preference_dao.dart';
part 'daos/goal_preference_dao_keys.dart';
part 'daos/goal_preference_dao_devices.dart';
part 'daos/goal_preference_dao_pending_sync.dart';
part 'daos/goal_preference_dao_sync_records.dart';
part 'app_database_lifecycle.dart';
part 'app_database_schema.dart';

/// Database Manager เชื่อมต่อโครงสร้างฐานข้อมูล SQLite ตาม `HealthyMate.sql`
class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  AppDatabase._internal();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// PBKDF2-HMAC-SHA256 password hash with a random per-password salt.
  static String hashPassword(String password) {
    final actualSalt = base64Url.encode(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)),
    );
    const iterations = 60000;
    final derived = _pbkdf2(password, actualSalt, iterations);
    return 'pbkdf2\$$iterations\$$actualSalt\$${base64Url.encode(derived)}';
  }

  static bool verifyPassword(String password, String encoded) {
    try {
      final parts = encoded.split(r'$');
      if (parts.length != 4 || parts[0] != 'pbkdf2') return false;
      final iterations = int.tryParse(parts[1]);
      if (iterations == null || iterations < 10000 || iterations > 1000000) {
        return false;
      }
      final expected = base64Url.decode(parts[3]);
      final actual = _pbkdf2(password, parts[2], iterations);
      if (actual.length != expected.length) return false;
      var difference = 0;
      for (var i = 0; i < actual.length; i++) {
        difference |= actual[i] ^ expected[i];
      }
      return difference == 0;
    } on FormatException {
      return false;
    }
  }

  static List<int> _pbkdf2(String password, String salt, int iterations) {
    final hmac = Hmac(sha256, utf8.encode(password));
    final first = hmac.convert([...utf8.encode(salt), 0, 0, 0, 1]).bytes;
    var block = List<int>.from(first);
    final output = List<int>.from(first);
    for (var i = 1; i < iterations; i++) {
      block = hmac.convert(block).bytes;
      for (var j = 0; j < output.length; j++) {
        output[j] ^= block[j];
      }
    }
    return output;
  }

  /// Legacy hashes are accepted only for migration during successful login.
  static String hashPasswordLegacy(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static String hashPasswordLegacySalted(String password, String email) {
    return sha256
        .convert(utf8.encode('HM_Salt_${email.trim().toLowerCase()}_$password'))
        .toString();
  }

  static const String _dbName = 'HealthyMate.db';

  // Table Names matching HealthyMate.sql
  static const String tableUsers = 'TbUsers';
  static const String tableHealthRecords = 'TbHealthRecords';
  static const String tableWorkouts = 'TbWorkouts';
  static const String tableWorkoutCategories = 'TbWorkoutCategories';
  static const String tableNutritionLogs = 'TbNutritionLogs';
  static const String tableRoutines = 'TbRoutines';
  static const String tableRoutineLogs = 'TbRoutineLogs';
  static const String tableBadges = 'TbBadges';
  static const String tableUserBadges = 'TbUserBadges';
  static const String tableHealthIntegrations = 'TbHealthIntegrations';
  static const String tableSession = 'TbSession';
  static const String tablePendingDeletions = 'TbPendingDeletions';

  Database? _db;

  // Web Fallback Storage
  final List<Map<String, dynamic>> _webUsers = [];
  final List<Map<String, dynamic>> _webHealthRecords = [];
  Map<String, dynamic>? _webSession;

  static void ensureInitialized() {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_db != null && _db!.isOpen) return _db!;
    _db = await _initDatabase();
    return _db!;
  }
}
