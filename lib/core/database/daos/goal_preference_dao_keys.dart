part of '../app_database.dart';

extension AppDatabaseKeysDao on AppDatabase {
  Future<String> getGeminiApiKey(int userId) async {
    if (kIsWeb) return '';
    final storageKey = 'gemini_api_key_$userId';
    String? secureValue;
    try {
      secureValue = await AppDatabase._secureStorage.read(key: storageKey);
    } catch (_) {}
    if (secureValue != null && secureValue.isNotEmpty) return secureValue;
    final db = await database;
    if (db == null) return '';
    try {
      final maps = await db.query(
        'TbUserPreferences',
        where: 'nUserId = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (maps.isNotEmpty && maps.first['sGeminiApiKey'] != null) {
        final legacyValue = maps.first['sGeminiApiKey'].toString();
        if (legacyValue.isNotEmpty) {
          await AppDatabase._secureStorage.write(
            key: storageKey,
            value: legacyValue,
          );
          await db.update(
            'TbUserPreferences',
            {'sGeminiApiKey': ''},
            where: 'nUserId = ?',
            whereArgs: [userId],
          );
          return legacyValue;
        }
      }
    } catch (e) {
      debugPrint('getGeminiApiKey error: $e');
    }
    return '';
  }

  Future<void> saveGeminiApiKey(int userId, String apiKey) async {
    if (kIsWeb) return;
    final normalizedKey = apiKey.trim();
    final storageKey = 'gemini_api_key_$userId';
    if (normalizedKey.isEmpty) {
      await AppDatabase._secureStorage.delete(key: storageKey);
    } else {
      await AppDatabase._secureStorage.write(
        key: storageKey,
        value: normalizedKey,
      );
    }
    final db = await database;
    if (db == null) return;
    try {
      try {
        await db.execute(
          'ALTER TABLE TbUserPreferences ADD COLUMN sGeminiApiKey TEXT DEFAULT ""',
        );
      } catch (_) {}

      final existing = await db.query(
        'TbUserPreferences',
        where: 'nUserId = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        await db.update(
          'TbUserPreferences',
          {'sGeminiApiKey': ''},
          where: 'nUserId = ?',
          whereArgs: [userId],
        );
      } else {
        await db.insert('TbUserPreferences', {
          'nUserId': userId,
          'sUnitSystem': 'metric',
          'sUnitLabel': 'Kilometers, Kilograms',
          'sGeminiApiKey': '',
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      debugPrint('saveGeminiApiKey error: $e');
      rethrow;
    }
  }
}
