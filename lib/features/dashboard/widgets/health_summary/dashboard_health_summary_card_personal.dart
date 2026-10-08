part of 'dashboard_health_summary_card.dart';

// ส่วนแสดงผลข้อมูลสุขภาพส่วนบุคคล (_DashboardHealthSummaryCardPersonal)
// ประกอบด้วย: หัวข้อ + ปุ่มอัปเดต, น้ำหนัก/ส่วนสูง, ดัชนีมวลกาย (BMI), BMR และ TDEE
extension _DashboardHealthSummaryCardPersonal on DashboardHealthSummaryCard {
  /// ฟังก์ชัน: สร้าง UI ส่วนข้อมูลสุขภาพส่วนบุคคล
  Widget _buildPersonalHealthSection({
    required bool isDark,
    required Color textPrimary,
    required Color textSecondary,
    required Color subtleSurface,
    required double weight,
    required double height,
    required double bmi,
    required dynamic bmiCategory,
    required double bmr,
    required double tdee,
    required String lastRecordText,
  }) => Column(
    children: [
      // ----------------------------------------------------
      // แถวที่ 1: หัวข้อข้อมูลสุขภาพ + ปุ่มกดไปหน้าคำนวณสุขภาพ (อัปเดตข้อมูล)
      // ----------------------------------------------------
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.health_and_safety, color: primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ข้อมูลสุขภาพส่วนบุคคล',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        lastRecordText,
                        style: TextStyle(fontSize: 11.5, color: textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // ปุ่มลัด: อัปเดตข้อมูล (นำทางไปยังหน้า Health Calculator)
          Material(
            color: isDark ? const Color(0xFF1E3A5F) : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onNavigateToCalculator,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sync,
                      size: 15,
                      color: isDark ? Colors.lightBlueAccent : Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'อัปเดตข้อมูล',
                      style: TextStyle(
                        color: isDark ? Colors.lightBlueAccent : Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // ----------------------------------------------------
      // แถวที่ 2: น้ำหนัก/ส่วนสูง และ ดัชนีมวลกาย (BMI + สถานะเกณฑ์)
      // ----------------------------------------------------
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // กล่องน้ำหนักและส่วนสูง
          Expanded(
            child: _buildStatItem(
              'น้ำหนัก / ส่วนสูง',
              weight > 0
                  ? '${_formatNumber(weight)} กก. | ${_formatNumber(height)} ซม.'
                  : 'ยังไม่ระบุ',
              subtleSurface,
              textPrimary,
              textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          // กล่อง BMI พร้อม Badge สถานะ (เช่น สมส่วน, น้ำหนักเกิน)
          Expanded(
            child: _buildStatItemWithBadge(
              'ดัชนีมวลกาย',
              bmi > 0 ? bmi.toStringAsFixed(1) : '-',
              bmi > 0 ? bmiCategory.badgeText : 'ยังไม่ระบุ',
              bmi > 0 ? bmiCategory.color : Colors.grey,
              subtleSurface,
              textPrimary,
              textSecondary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),

      // ----------------------------------------------------
      // แถวที่ 3: อัตราเผาผลาญพลังงานพื้นฐาน (BMR) และ พลังงานที่ต้องการต่อวัน (TDEE)
      // ----------------------------------------------------
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // กล่อง BMR
          Expanded(
            child: _buildStatItemWithWidget(
              'BMR พลังงานพื้นฐาน',
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: bmr),
                duration: const Duration(milliseconds: 2500),
                curve: Curves.easeOutCubic,
                builder: (context, val, _) => Text(
                  bmr > 0 ? '${val.round()} kcal' : '- kcal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textPrimary,
                  ),
                ),
              ),
              subtleSurface,
              textSecondary,
              icon: Icons.bolt,
            ),
          ),
          const SizedBox(width: 8),
          // กล่อง TDEE
          Expanded(
            child: _buildStatItemWithWidget(
              'TDEE ต้องการต่อวัน',
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: tdee),
                duration: const Duration(milliseconds: 2500),
                curve: Curves.easeOutCubic,
                builder: (context, val, _) => Text(
                  tdee > 0 ? '${val.round()} kcal' : '- kcal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textPrimary,
                  ),
                ),
              ),
              subtleSurface,
              textSecondary,
              icon: Icons.local_fire_department,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
    ],
  );
}

