part of 'health_calculator_controller.dart';

extension HealthCalculatorPersistence on HealthCalculatorController {
  Future<void> saveToProfileAndDashboard() async {
    await calculate(recordHistory: true, syncToDb: true);
    _isSyncedToDashboard = true;
    _lastSyncedAt = DateTime.now();
    RoutineStateNotifier.instance.loadData(userId: _currentUser?.nUserId);
    _safeNotifyListeners();
  }

  Future<void> deleteHistoryItem(int recordId) async {
    try {
      await _db.deleteHealthRecord(recordId);
      _historyList.removeWhere((item) => item.nRecordId == recordId);
      RoutineStateNotifier.instance.loadData(userId: _currentUser?.nUserId);
      _safeNotifyListeners();
    } catch (e) {
      debugPrint('Error deleting health record from db: $e');
    }
  }
}
