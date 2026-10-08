part of 'dashboard_health_summary_card.dart';

// ส่วนคอมโพเนนต์ไอเทมสถิติพื้นฐาน (_DashboardHealthSummaryCardStatUi)
// Widget ช่วยสร้างกล่องข้อมูลสถิติ (Stat Item, Stat with Widget, Stat with Badge)
extension _DashboardHealthSummaryCardStatUi on DashboardHealthSummaryCard {
  /// ฟังก์ชัน: สร้างกล่องสถิติที่ใช้ Custom Widget แสดงผลค่าตัวเลข (เช่น TweenAnimationBuilder)
  Widget _buildStatItemWithWidget(
    String title,
    Widget valueWidget,
    Color surfaceColor,
    Color secondaryColor, {
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // แถวไอคอนและชื่อสถิติ
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: secondaryColor),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, color: secondaryColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          valueWidget,
        ],
      ),
    );
  }

  /// ฟังก์ชัน: สร้างกล่องสถิติทั่วไป (Text Title + Text Value)
  Widget _buildStatItem(
    String title,
    String value,
    Color surfaceColor,
    Color primaryColor,
    Color secondaryColor, {
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // แถวไอคอนและชื่อสถิติ
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: secondaryColor),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, color: secondaryColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // ข้อความค่าสถิติ
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// ฟังก์ชัน: สร้างกล่องสถิติพร้อมป้ายสถานะ Badge (เช่น BMI พร้อม Badge เกณฑ์สุขภาพ)
  Widget _buildStatItemWithBadge(
    String title,
    String value,
    String badgeText,
    Color badgeColor,
    Color surfaceColor,
    Color primaryColor,
    Color secondaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ชื่อสถิติ
          Text(
            title,
            style: TextStyle(fontSize: 11, color: secondaryColor),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // ค่าสถิติและ Badge สถานะ
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 2,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: primaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

