part of 'completed_goals_and_routines_page.dart';
// ฟังก์ชันสำหรับโหลดข้อมูลประวัติเป้าหมายและการออกกำลังกายที่สำเร็จ
extension CompletedGoalsHistory on _CompletedGoalsAndRoutinesPageState {
  Future<void> _loadHistoryData() async {
    setState(() => _isLoading = true);
    try {
      final db = AppDatabase.instance;
      final user = await db.getCurrentUser();
      if (user == null) return;
      final userId = user.nUserId;

      // 1. ดึงประวัติเป้าหมายหลัก
      final allGoals = await db.getAllUserGoalsHistory(userId);
      // กรองเฉพาะเป้าหมายที่ทำสำเร็จ หรือมีความคืบหน้า 100%
      _completedGoals = allGoals.where((g) {
        final progress = (g['nProgress'] as num?)?.toDouble() ?? 0.0;
        final remaining = g['sRemainingText']?.toString() ?? '';
        return progress >= 1.0 || remaining.contains('100%');
      }).toList();

      // 2. ดึงประวัติกิจวัตรที่ทำสำเร็จ
      _completedRoutines = await db.getCompletedRoutineLogsHistory(
        userId: userId,
      );
    } catch (e) {
      debugPrint('Error loading completed history: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  // ฟังก์ชันสำหรับแปลงวันที่ให้เป็นรูปแบบไทย
  String _formatThaiDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return 'ไม่ระบุวันที่';
    try {
      final dt = DateTime.parse(rawDate);
      const thaiMonths = [
        'ม.ค.',
        'ก.พ.',
        'มี.ค.',
        'เม.ย.',
        'พ.ค.',
        'มิ.ย.',
        'ก.ค.',
        'ส.ค.',
        'ก.ย.',
        'ต.ค.',
        'พ.ย.',
        'ธ.ค.',
      ];
      final thaiYear = dt.year > 2500 ? dt.year : dt.year + 543;
      return '${dt.day} ${thaiMonths[dt.month - 1]} $thaiYear';
    } catch (_) {
      return rawDate;
    }
  }
}
