import 'package:flutter/material.dart';

/// การ์ดแสดงความก้าวหน้ากิจกรรมประจำวันแบบวงกลม (Daily Activity Progress Ring Card)
class DailyActivityCard extends StatelessWidget {
  /// สัดส่วนความก้าวหน้ากิจกรรม (ค่าระหว่าง 0.0 - 1.0)
  final double progress; 
  /// Callback เมื่อกดปุ่มเริ่มออกกำลังกาย
  final VoidCallback onStartWorkout;

  const DailyActivityCard({
    super.key,
    required this.progress,
    required this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
    // แปลงค่าทศนิยมเป็นเปอร์เซ็นต์จำนวนเต็ม (0 - 100%)
    final percentage = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----------------------------------------------------
          // 1. หัวข้อการ์ดและคำอธิบายเป้าหมาย (Title & Subtitle)
          // ----------------------------------------------------
          const Text(
            'กิจกรรมประจำวัน',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C2819),
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'คุณทำสำเร็จแล้ว $percentage% ของเป้าหมายประจำวัน เดินอีกแค่ 20 นาทีก็จะถึงเป้าหมายแล้ว!',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF5A6559),
            ),
          ),
          const SizedBox(height: 16),

          // ----------------------------------------------------
          // 2. ปุ่มกดเริ่มออกกำลังกาย (Start Workout Button)
          // ----------------------------------------------------
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onStartWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E5327), // โทนสีเขียวเข้ม Deep Forest Green
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 22, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'เริ่มออกกำลังกาย',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ----------------------------------------------------
          // 3. กราฟวงกลมแสดงความก้าวหน้า (Circular Progress Indicator)
          // ----------------------------------------------------
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // วงแหวน Progress Ring
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 16,
                      backgroundColor: const Color(0xFFE5EBE3), // สีพื้นหลังวงแหวนโทนเขียวอ่อน
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E5327)), // สีเขียวเข้มตามความก้าวหน้า
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // ตัวเลขเปอร์เซ็นต์ตรงกลางวงแหวน
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$percentage%',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C2819),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'สำเร็จแล้ว',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF5A6559),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

