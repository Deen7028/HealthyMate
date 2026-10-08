part of 'key_stats_grid.dart';

// ==========================================
// ส่วนคอมโพเนนต์การ์ดสถิติย่อย (_KeyStatsGridCards)
// ประกอบด้วยการ์ดสถิติขนาดเล็ก (Small Card) และการ์ดสถิติขนาดเต็มความกว้าง (Large Card)
// ==========================================
extension _KeyStatsGridCards on KeyStatsGrid {
  /// ฟังก์ชัน: สร้าง UI การ์ดสถิติขนาดกะทัดรัด (Small Stat Card เช่น ระยะทาง, เวลา)
  /// - [icon]: ไอคอนประจำสถิติ
  /// - [iconColor]: สีของไอคอน
  /// - [title]: ชื่อสถิติ (เช่น 'ระยะทาง')
  /// - [value]: ค่าตัวเลขที่วัดได้
  /// - [unit]: หน่วยของค่าสถิติ (เช่น 'กม.', 'นาที')
  /// - [progressRatio]: อัตราส่วนความคืบหน้าของหลอดแถบสี (0.0 - 1.0)
  /// - [progressColor]: สีของแถบความคืบหน้า
  Widget _buildSmallStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
    required double progressRatio,
    required Color progressColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. แถวไอคอน + ชื่อสถิติ
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A6559),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. แถวแสดงค่าตัวเลข + หน่วย
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C2819),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A6559),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. แถบแสดงความคืบหน้า (Progress Bar)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 6,
              backgroundColor: const Color(0xFFF0F4EF),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  /// ฟังก์ชัน: สร้าง UI การ์ดสถิติขนาดใหญ่เต็มความกว้าง (Large Stat Card เช่น แคลอรี)
  /// - [icon]: ไอคอนประจำสถิติ
  /// - [iconColor]: สีของไอคอน
  /// - [title]: ชื่อสถิติ (เช่น 'แคลอรี่')
  /// - [value]: ค่าตัวเลขที่วัดได้
  /// - [unit]: หน่วยของค่าสถิติ (เช่น 'กิโลแคลอรี่')
  /// - [progressRatio]: อัตราส่วนความคืบหน้าของหลอดแถบสี (0.0 - 1.0)
  /// - [progressColor]: สีของแถบความคืบหน้า
  Widget _buildLargeStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
    required double progressRatio,
    required Color progressColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. แถวไอคอน + ชื่อสถิติ
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A6559),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. แถวแสดงค่าตัวเลข + หน่วย
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1C2819),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A6559),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3. แถบแสดงความคืบหน้า (Progress Bar)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 6,
              backgroundColor: const Color(0xFFF0F4EF),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}

