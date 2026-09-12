import 'package:flutter/material.dart';

class DailyActivityCard extends StatelessWidget {
  final double progress; // 0.75 for 75%
  final VoidCallback onStartWorkout;

  const DailyActivityCard({
    super.key,
    required this.progress,
    required this.onStartWorkout,
  });

  @override
  Widget build(BuildContext context) {
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
          // Card Title
          const Text(
            'กิจกรรมประจำวัน',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C2819),
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle text matching design image
          Text(
            'คุณทำสำเร็จแล้ว $percentage% ของเป้าหมายประจำวัน เดินอีกแค่ 20 นาทีก็จะถึงเป้าหมายแล้ว!',
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF5A6559),
            ),
          ),
          const SizedBox(height: 16),

          // Start Workout Button (Deep Forest Green)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onStartWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E5327), // Deep Forest Green from image
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

          // Center Progress Ring
          Center(
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 16,
                      backgroundColor: const Color(0xFFE5EBE3), // Pale soft green grey
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E5327)), // Deep Forest Green
                      strokeCap: StrokeCap.round,
                    ),
                  ),
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
