import 'package:flutter/material.dart';
import 'package:healthymate/features/practice/models/routine_item.dart';

class ProgressSummaryCard extends StatelessWidget {
  final List<RoutineItem> routines;
  final VoidCallback? onResetAll;

  const ProgressSummaryCard({
    super.key,
    required this.routines,
    this.onResetAll,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = routines.length;
    final completedCount = routines.where((r) => r.isCompleted).length;
    final activeNotificationsCount = routines.where((r) => r.isNotificationEnabled).length;
    final overallRatio = totalCount > 0 ? completedCount / totalCount : 0.0;
    final overallPercentage = (overallRatio * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withAlpha(51),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          color: Color(0xFF10B981),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'ความคืบหน้ารวมวันนี้',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'สำเร็จ $completedCount จาก $totalCount กิจวัตร',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      value: overallRatio,
                      strokeWidth: 7,
                      backgroundColor: Colors.white.withAlpha(25),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '$overallPercentage%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: overallRatio,
              minHeight: 8,
              backgroundColor: Colors.white.withAlpha(25),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withAlpha(25), height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatTile(
                icon: Icons.notifications_active_rounded,
                iconColor: const Color(0xFF38BDF8),
                value: '$activeNotificationsCount รายการ',
                label: 'แจ้งเตือนทำงานอยู่',
              ),
              Container(height: 30, width: 1, color: Colors.white.withAlpha(25)),
              _buildStatTile(
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF34D399),
                value: '$completedCount กิจวัตร',
                label: 'เป้าหมายที่บรรลุ',
              ),
              Container(height: 30, width: 1, color: Colors.white.withAlpha(25)),
              _buildStatTile(
                icon: Icons.schedule_rounded,
                iconColor: const Color(0xFFFBBF24),
                value: '${totalCount - completedCount} รายการ',
                label: 'รอการปฏิบัติตาม',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
