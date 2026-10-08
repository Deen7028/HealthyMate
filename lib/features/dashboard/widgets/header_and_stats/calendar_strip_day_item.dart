part of 'calendar_strip_widget.dart';

// ส่วนแสดงผลไอเทมแต่ละวันใน Calendar Strip
extension _CalendarStripDayItem on CalendarStripWidget {
  /// ฟังก์ชัน: สร้าง UI การ์ดแสดงผลของแต่ละวัน (Day Column Item)
  /// - [day]: ชื่อย่อของวัน (เช่น 'จ.', 'อ.')
  /// - [date]: วันที่ประจำเดือน (เช่น '1', '15')
  /// - [isSelected]: วันนี้ตรงกับวันปัจจุบันหรือไม่
  /// - [isPast]: วันนี้ผ่านมาแล้วหรือไม่
  /// - [isDark]: โหมดธีมมืด (Dark Mode) หรือไม่
  Widget _buildDayItem(
    String day,
    String date,
    bool isSelected,
    bool isPast,
    bool isDark,
  ) {
    return Column(
      children: [
        // 1. ป้ายชื่อย่อของวัน (Day Label)
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? darkGreen
                : (isDark ? const Color(0xFFA0ACA0) : Colors.grey),
          ),
        ),
        const SizedBox(height: 8),

        // 2. กล่องแสดงตัวเลขวันที่ (Date Capsule)
        Container(
          width: 32,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? darkGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              date,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),

        // 3. จุดสถานะกิจกรรมใต้ตัวเลขวันที่ (Status Indicator Dot)
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.greenAccent
                : (isPast
                      ? darkGreen
                      : (isDark
                            ? const Color(0xFF3B4D41)
                            : Colors.grey.shade300)),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

