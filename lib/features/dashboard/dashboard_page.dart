import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

// สมมติว่ามีการ import ข้อมูล/State เข้ามา
// import 'package:healthymate/features/health_calculator/state/health_calculator_state.dart';

class DashboardPageUpdated extends StatefulWidget {
  final VoidCallback? onNavigateToCalculator;
  final VoidCallback? onNavigateToPractice;
  final VoidCallback? onNavigateToWorkout;
  final VoidCallback? onStartWorkout;

  const DashboardPageUpdated({
    super.key,
    this.onNavigateToCalculator,
    this.onNavigateToPractice,
    this.onNavigateToWorkout,
    this.onStartWorkout,
  });

  @override
  State<DashboardPageUpdated> createState() => _DashboardPageUpdatedState();
}

class _DashboardPageUpdatedState extends State<DashboardPageUpdated> {
  // สีหลักอ้างอิงจากดีไซน์
  final Color primaryGreen = const Color(0xFF0F9C58);
  final Color darkGreen = const Color(0xFF006432);
  final Color lightBg = const Color(0xFFF7F9FB);

  void _handleStartWorkout() {
    if (widget.onNavigateToWorkout != null) {
      widget.onNavigateToWorkout!();
    } else if (widget.onStartWorkout != null) {
      widget.onStartWorkout!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('กำลังเข้าสู่โหมดมินิมาราธอน... 🏃‍♂️'),
          backgroundColor: darkGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg, // สีพื้นหลังโทนสว่าง
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Header
                _buildHeader(),
                const SizedBox(height: 24),

                // 2. ข้อมูลสุขภาพส่วนบุคคล (Health Summary Card)
                _buildHealthSummaryCard(),
                const SizedBox(height: 20),

                // 3. เป้าหมายหลักของฉัน (Main Goal Card)
                _buildMainGoalCard(),
                const SizedBox(height: 20),

                // 4. ปุ่มลัดเริ่มออกกำลังกาย
                _buildActionButtons(),
                const SizedBox(height: 20),

                // 5. เป้าหมายอื่นๆ (Other Goals & Routines)
                _buildOtherGoalsCard(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget ส่วนบน (Header) ---
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&w=150&q=80'),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HealthyMate',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen),
                      ),
                      Row(
                        children: [
                          Icon(Icons.circle, color: primaryGreen, size: 8),
                          const SizedBox(width: 4),
                          const Text('เข้าสู่วันจันทร์ • สัปดาห์ที่ 3',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      )
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
                color: Colors.black87,
              )
            ],
          ),
          const SizedBox(height: 20),
          RichText(
            text: const TextSpan(
              style: TextStyle(color: Colors.black87, fontSize: 24),
              children: [
                TextSpan(
                    text: 'อรุณสวัสดิ์, สมชาย! ☀️\n',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(
                  text: 'พร้อมออกไปวิ่งรับพลังงานยามเช้าและดูแลสุขภาพที่ดีหรือยัง?',
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget การ์ดข้อมูลสุขภาพ (Card 1) ---
  Widget _buildHealthSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.health_and_safety, color: darkGreen),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ข้อมูลสุขภาพส่วนบุคคล',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('คำนวณล่าสุดเมื่อเช้านี้',
                          style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: widget.onNavigateToCalculator,
                icon: const Icon(Icons.sync, size: 16, color: Colors.blue),
                label: const Text('อัปเดตข้อมูล', style: TextStyle(color: Colors.blue, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          // สถิติย่อย 4 ช่อง
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('น้ำหนัก / ส่วนสูง', '65 กก. | 170 ซม.'),
              _buildStatItemWithBadge('ดัชนีมวลกาย', '22.4', 'สมส่วน (Normal)', Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('BMR พลังงานพื้นฐาน', '1,520 kcal', icon: Icons.bolt),
              _buildStatItem('TDEE ต้องการต่อวัน', '2,100 kcal', icon: Icons.local_fire_department),
            ],
          ),
          const SizedBox(height: 16),
          // กล่องเป้าหมายเผาผลาญ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.track_changes, color: primaryGreen),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('เป้าหมายเผาผลาญจากการออกกำลังกาย',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                      Text('เพื่อช่วยลดไขมันและรักษารูปร่างตามเป้าหมายหลัก',
                          style: TextStyle(fontSize: 10, color: Colors.black54)),
                    ],
                  ),
                ),
                Text('400\nkcal/วัน',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- Widget ย่อยสำหรับการ์ดข้อมูลสุขภาพ ---
  Widget _buildStatItem(String title, String value, {IconData? icon}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (icon != null) ...[const SizedBox(width: 4), Icon(icon, size: 14, color: Colors.orange)],
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatItemWithBadge(String title, String value, String badgeText, Color badgeColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badgeText, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ],
      ),
    );
  }

  // --- Widget การ์ดเป้าหมายหลัก (Card 2) ---
  Widget _buildMainGoalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryGreen.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.flag, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('เป้าหมายหลักของฉัน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: primaryGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text('เหลืออีก 12 วัน', style: TextStyle(color: darkGreen, fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 24),
          // Circular Progress
          CircularPercentIndicator(
            radius: 60.0,
            lineWidth: 12.0,
            percent: 0.68,
            center: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("68%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                Text("สำเร็จแล้ว", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            progressColor: primaryGreen,
            backgroundColor: Colors.grey.shade200,
            circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 24),
          const Text('🏃 วิ่ง 500 กิโลเมตร ใน 1 เดือน',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('วิ่งสะสม: 340 / 500 กม. (เหลือ 160 กม.)',
              style: TextStyle(fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 16),
          // Tip Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'คำแนะนำวันนี้: เพื่อให้ถึงเป้าหมาย 500 กม. ควรเก็บระยะทางวันนี้ 15-18 กม. คุมโซน 2 เพื่อรักษาระดับความฟิตและป้องกันการล้า',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- Widget ปุ่ม Action (Start Workout) ---
  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _handleStartWorkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bolt, color: Colors.yellow),
                SizedBox(width: 8),
                Text('เริ่มวิ่งมินิมาราธอน (30 นาที)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.swap_calls, color: Colors.black54),
                SizedBox(width: 8),
                Text('เลือกประเภทอื่น', style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Widget เป้าหมายอื่นๆ (Card 3) ---
  Widget _buildOtherGoalsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.format_list_bulleted, color: Colors.blueGrey),
                  SizedBox(width: 8),
                  Text('เป้าหมายอื่นๆ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text('ดูทั้งหมด >', style: TextStyle(fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 12),
          _buildMiniGoalProgress(icon: Icons.water_drop, color: Colors.blue, title: 'ดื่มน้ำ', current: '1.5', target: '2.5 ลิตร', percent: 0.6),
          const SizedBox(height: 16),
          _buildMiniGoalProgress(icon: Icons.directions_walk, color: Colors.orange, title: 'เดิน', current: '6,000', target: '10,000 ก้าว', percent: 0.6),
          const SizedBox(height: 16),
          _buildMiniGoalProgress(icon: Icons.bedtime, color: Colors.purple, title: 'นอนหลับ', current: '6', target: '8 ชม.', percent: 0.75),
        ],
      ),
    );
  }

  Widget _buildMiniGoalProgress({required IconData icon, required Color color, required String title, required String current, required String target, required double percent}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            Row(
              children: [
                Text('$current / $target', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(width: 8),
                Text('${(percent * 100).toInt()}%', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearPercentIndicator(
          lineHeight: 8.0,
          percent: percent,
          progressColor: color,
          backgroundColor: Colors.grey.shade200,
          barRadius: const Radius.circular(4),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }


}