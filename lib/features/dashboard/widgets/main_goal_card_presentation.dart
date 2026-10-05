// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์แดชบอร์ดสรุปสุขภาพและเป้าหมาย (main goal card presentation)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'main_goal_card_setup_button.dart';
import 'main_goal_card_status_footer.dart';

class MainGoalCardPresentation extends StatelessWidget {
  final bool hasPinnedGoal;
  final Color goalColor;
  final IconData goalIcon;
  final String displayTitle;
  final String displayDetail;
  final bool isCompleted;
  final double progress;
  final String remainingValText;
  final String deadlineSubText;
  final bool isDark;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final VoidCallback onCreateGoal;
  final Widget Function(
    String,
    String,
    Color,
    Color, {
    IconData? icon,
    String? subValue,
  })
  buildGoalStatItem;

  const MainGoalCardPresentation({
    super.key,
    required this.hasPinnedGoal,
    required this.goalColor,
    required this.goalIcon,
    required this.displayTitle,
    required this.displayDetail,
    required this.isCompleted,
    required this.progress,
    required this.remainingValText,
    required this.deadlineSubText,
    required this.isDark,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.onCreateGoal,
    required this.buildGoalStatItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasPinnedGoal
              ? goalColor.withValues(alpha: 0.35)
              : borderColor,
          width: hasPinnedGoal ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: goalColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(goalIcon, color: goalColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasPinnedGoal) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.push_pin,
                            size: 14,
                            color: Colors.orange.shade700,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayDetail,
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted
                            ? (isDark
                                  ? const Color(0xFF90DB89)
                                  : Colors.green.shade700)
                            : textSecondary,
                        fontWeight: isCompleted
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!hasPinnedGoal) ...[
            const SizedBox(height: 16),
            MainGoalCardSetupButton(onPressed: onCreateGoal),
          ] else ...[
            const SizedBox(height: 16),

            CircularPercentIndicator(
              radius: 54.0,
              lineWidth: 9.0,
              percent: progress,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: goalColor,
                    ),
                  ),
                  Text(
                    isCompleted ? 'สำเร็จ!' : 'ความคืบหน้า',
                    style: TextStyle(
                      fontSize: 9,
                      color: isCompleted ? Colors.green.shade800 : Colors.grey,
                      fontWeight: isCompleted
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              progressColor: goalColor,
              backgroundColor: goalColor.withValues(alpha: 0.12),
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
            ),
          ],

          MainGoalCardStatusFooter(
            isCompleted: isCompleted,
            hasPinnedGoal: hasPinnedGoal,
            remainingValText: remainingValText,
            deadlineSubText: deadlineSubText,
            borderColor: borderColor,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            buildGoalStatItem: buildGoalStatItem,
          ),
        ],
      ),
    );
  }
}
