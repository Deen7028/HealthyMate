import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/core/utils/health_calculator.dart';

class CalorieTargetSection extends StatelessWidget {
  final CalorieTargets targets;

  const CalorieTargetSection({
    super.key,
    required this.targets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.subtleSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.flag_outlined,
                size: 18,
                color: AppTheme.primaryGreen,
              ),
              SizedBox(width: 8),
              Text(
                'เป้าหมายแคลอรีแนะนำ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildGoalCard(
                  title: 'ลดไขมัน',
                  calories: targets.fatLoss.toString(),
                  subtext: '-500 kcal',
                  isHighlighted: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGoalCard(
                  title: 'คงน้ำหนัก',
                  calories: targets.maintain.toString(),
                  subtext: 'พอดีวัน',
                  isHighlighted: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGoalCard(
                  title: 'เพิ่มกล้ามเนื้อ',
                  calories: targets.muscleGain.toString(),
                  subtext: '+300 kcal',
                  isHighlighted: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard({
    required String title,
    required String calories,
    required String subtext,
    required bool isHighlighted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? AppTheme.primaryGreen : AppTheme.borderLight,
          width: isHighlighted ? 1.6 : 1.0,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isHighlighted ? AppTheme.primaryGreen : AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            calories,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isHighlighted ? AppTheme.textSecondary : AppTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
