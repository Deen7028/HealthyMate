import 'package:flutter/material.dart';

class RoutineMainGoalCard extends StatelessWidget {
  final Map<String, dynamic>? userGoal;
  final int completedCount;
  final int totalRoutinesCount;
  final VoidCallback onUnpin;
  final Color cardGreenBg;
  final Color primaryGreen;
  final Color darkGreen;

  const RoutineMainGoalCard({
    super.key,
    required this.userGoal,
    required this.completedCount,
    required this.totalRoutinesCount,
    required this.onUnpin,
    this.cardGreenBg = const Color(0xFFE8F5E9),
    this.primaryGreen = const Color(0xFF0F9C58),
    this.darkGreen = const Color(0xFF006432),
  });

  @override
  Widget build(BuildContext context) {
    final goalTitle = userGoal?['sTitle']?.toString() ?? '';

    if (goalTitle.isEmpty) {
      return const SizedBox.shrink();
    }

    final goalProgress = (userGoal?['nProgress'] as num?)?.toDouble() ?? 0.0;
    final goalRemaining = userGoal?['sRemainingText']?.toString() ?? '';
    final String subtitle = goalRemaining.isNotEmpty
        ? goalRemaining
        : 'ทำสำเร็จแล้ว ${(goalProgress * 100).toInt()}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: cardGreenBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGreen.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: darkGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🚩 กิจวัตรจากเป้าหมายหลัก',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.grey,
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'unpin') onUnpin();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'unpin',
                      child: Row(
                        children: [
                          Icon(Icons.close, color: Colors.grey, size: 20),
                          SizedBox(width: 8),
                          Text('ยกเลิกเป้าหมายหลัก'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: darkGreen.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.flag, color: darkGreen),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goalTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.checklist, size: 18, color: darkGreen),
                      const SizedBox(width: 8),
                      Text(
                        'วันนี้ทำสำเร็จ $completedCount / $totalRoutinesCount กิจวัตร',
                        style: TextStyle(
                          fontSize: 13,
                          color: darkGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (totalRoutinesCount > 0)
                        Text(
                          '${(completedCount / totalRoutinesCount * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 13,
                            color: darkGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
