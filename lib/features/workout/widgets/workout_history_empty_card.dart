import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';

class WorkoutHistoryEmptyCard extends StatelessWidget {
  final VoidCallback onSyncTap;

  const WorkoutHistoryEmptyCard({
    super.key,
    required this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1E7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFD4E6D2),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      size: 48,
                      color: Color(0xFF2E5327),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ยังไม่มีประวัติการออกกำลังกาย',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C2819),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'เลื่อนลงเพื่อดึงข้อมูลจาก Cloud หรือเริ่มบันทึกกิจกรรมวิ่ง เดิน หรือปั่นจักรยานใหม่',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF677366),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: onSyncTap,
                    icon: const Icon(Icons.cloud_download_outlined, size: 18),
                    label: const Text('ดึงข้อมูลทั้งหมดจาก Server'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: const BorderSide(color: AppTheme.primaryGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
