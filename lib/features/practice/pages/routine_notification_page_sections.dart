// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์กิจวัตรและเป้าหมายประจำวัน (routine notification page sections)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'routine_notification_page.dart';

extension _RoutineNotificationSections on _MyRoutinesPageState {
  String _getTimeBlock(String? time) {
    if (time == null || time.isEmpty) return 'other';
    final match = RegExp(r'(\d{1,2})[:\.](\d{2})').firstMatch(time);
    if (match != null) {
      final hour = int.tryParse(match.group(1) ?? '') ?? 12;
      if (hour < 12) return 'morning';
      if (hour < 18) return 'afternoon';
      return 'night';
    }
    if (time.contains('เช้า') || time.contains('Morning')) return 'morning';
    if (time.contains('บ่าย') || time.contains('Afternoon')) return 'afternoon';
    if (time.contains('เย็น') ||
        time.contains('คืน') ||
        time.contains('Night')) {
      return 'night';
    }
    return 'other';
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    final userName = _controller.user?.sFirstName ?? 'ผู้ใช้งาน';
    final profilePath = _controller.user?.sProfileImagePath ?? '';
    final scaffoldBg = AppTheme.getScaffoldColor(isDark);

    ImageProvider? imageProvider;
    if (profilePath.isNotEmpty) {
      if (profilePath.startsWith('http')) {
        imageProvider = NetworkImage(profilePath);
      }
    }

    return AppBar(
      backgroundColor: scaffoldBg,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'กิจวัตรของฉัน',
            style: TextStyle(
              color: isDark ? const Color(0xFF90DB89) : darkGreen,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            '(My Routines)',
            style: TextStyle(
              color: isDark ? const Color(0xFFA0ACA0) : Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: isDark ? 0.25 : 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFFE6A23C),
              size: 20,
            ),
          ),
          tooltip: 'ประวัติความสำเร็จ (Completed History)',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CompletedGoalsAndRoutinesPage(),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 4.0),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: primaryGreen,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const RoutineEmptyView();
  }

  Widget _buildDailyRoutinesHeader(bool isDark) {
    int timeBlockCount = 0;
    final times = _controller.routines
        .map((r) => this._getTimeBlock(r['sTime']?.toString() ?? ''))
        .toSet();
    timeBlockCount = times.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'กิจวัตรประจำวัน (Daily\nRoutines)',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: isDark ? Colors.white : const Color(0xFF1E2822),
          ),
        ),
        Text(
          _controller.routines.isEmpty
              ? 'ยังไม่มี'
              : '$timeBlockCount ช่วง\nเวลา',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFFA0ACA0) : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeBlockHeader(String title, String timeRange, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? const Color(0xFF90DB89) : const Color(0xFF1C2819),
            ),
          ),
          Text(
            timeRange,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFFA0ACA0) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
