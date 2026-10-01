part of '../app_database.dart';

extension AppDatabaseHealthRecordDao on AppDatabase {
  /// ดึงรายการประวัติทั้งหมดจาก `TbHealthRecords`
  Future<List<TbHealthRecord>> getHealthRecords({required int userId}) async {
    if (kIsWeb) {
      return _webHealthRecords
          .map((item) => TbHealthRecord.fromMap(item))
          .where((record) => record.nUserId == userId)
          .toList()
        ..sort((a, b) => b.dtRecordedAt.compareTo(a.dtRecordedAt));
    }

    final db = await database;
    if (db == null) return [];

    final maps = await db.query(
      AppDatabase.tableHealthRecords,
      where: 'nUserId = ?',
      whereArgs: [userId],
      orderBy: 'dtRecordedAt DESC',
    );

    return maps.map((map) => TbHealthRecord.fromMap(map)).toList();
  }

  /// เพิ่มบันทึกใหม่ใน `TbHealthRecords`
  Future<TbHealthRecord> insertHealthRecord(TbHealthRecord record) async {
    if (kIsWeb) {
      final newId = DateTime.now().millisecondsSinceEpoch % 1000000;
      final newRecord = TbHealthRecord(
        nRecordId: record.nRecordId == 0 ? newId : record.nRecordId,
        nUserId: record.nUserId,
        nWeight: record.nWeight,
        nHeight: record.nHeight,
        nBmi: record.nBmi,
        nTdee: record.nTdee,
        dtRecordedAt: record.dtRecordedAt,
        computedBmr: record.computedBmr,
        activityLevelTitle: record.activityLevelTitle,
      );
      _webHealthRecords.insert(0, newRecord.toMap());
      return newRecord;
    }

    final db = await database;
    final recordMap = record.toMap();
    if (record.nRecordId == 0) {
      recordMap.remove('nRecordId');
    }

    final id = await db!.insert(
      AppDatabase.tableHealthRecords,
      recordMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return TbHealthRecord(
      nRecordId: id,
      nUserId: record.nUserId,
      nWeight: record.nWeight,
      nHeight: record.nHeight,
      nBmi: record.nBmi,
      nTdee: record.nTdee,
      dtRecordedAt: record.dtRecordedAt,
      computedBmr: record.computedBmr,
      activityLevelTitle: record.activityLevelTitle,
    );
  }

  /// ลบบันทึกจาก `TbHealthRecords` ตาม Record ID พร้อมซิงค์ลบไปที่ Server
  Future<void> deleteHealthRecord(int recordId) async {
    if (kIsWeb) {
      _webHealthRecords.removeWhere((item) => item['nRecordId'] == recordId);
      await HealthRecordApiService.deleteHealthRecordRemote(recordId);
      return;
    }

    final db = await database;
    if (db == null) return;
    final rows = await db.query(
      AppDatabase.tableHealthRecords,
      where: 'nRecordId = ?',
      whereArgs: [recordId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final row = rows.first;
    final userId = (row['nUserId'] as num?)?.toInt() ?? 0;
    final wasSynced = (row['isSynced'] as num?)?.toInt() == 1;
    await db.transaction((txn) async {
      if (wasSynced && userId > 0) {
        await txn.insert(AppDatabase.tablePendingDeletions, {
          'nUserId': userId,
          'sEntity': 'health_record',
          'nRemoteId': recordId,
          'dtQueuedAt': DateTime.now().toIso8601String(),
        });
      }
      await txn.delete(
        AppDatabase.tableHealthRecords,
        where: 'nRecordId = ?',
        whereArgs: [recordId],
      );
    });
    if (wasSynced && userId > 0) {
      if (await HealthRecordApiService.deleteHealthRecordRemote(recordId)) {
        final pending = await db.query(
          AppDatabase.tablePendingDeletions,
          where: 'nUserId = ? AND sEntity = ? AND nRemoteId = ?',
          whereArgs: [userId, 'health_record', recordId],
          limit: 1,
        );
        if (pending.isNotEmpty) {
          await db.delete(
            AppDatabase.tablePendingDeletions,
            where: 'nDeletionId = ?',
            whereArgs: [pending.first['nDeletionId']],
          );
        }
      } else {
        unawaited(SyncService.instance.updatePendingCount());
        unawaited(SyncService.instance.syncPendingData());
      }
    }
    unawaited(SyncService.instance.updatePendingCount());
  }

  /// ล้างข้อมูล `TbHealthRecords` ทั้งหมด
  Future<void> clearHealthRecords() async {
    if (kIsWeb) {
      _webHealthRecords.clear();
      return;
    }

    final db = await database;
    if (db == null) return;
    await db.delete(AppDatabase.tableHealthRecords);
  }
}
