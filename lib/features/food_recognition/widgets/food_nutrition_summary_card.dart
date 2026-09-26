import 'package:flutter/material.dart';

class FoodNutritionSummaryCard extends StatelessWidget {
  final int totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final Color primaryColor;

  const FoodNutritionSummaryCard({
    super.key,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EBE5), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'พลังงานรวมทั้งสิ้น',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF5A6559),
                ),
              ),
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: totalCalories),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, val, _) {
                  return RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$val',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: primaryColor,
                          ),
                        ),
                        const TextSpan(
                          text: ' kcal',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7A867E),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2EBE5)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroItem(
                label: 'โปรตีน (P)',
                doubleValue: totalProtein,
                unit: 'g',
                color: const Color(0xFF2E6339),
                icon: Icons.egg_alt_outlined,
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE2EBE5)),
              _buildMacroItem(
                label: 'คาร์โบไฮเดรต (C)',
                doubleValue: totalCarbs,
                unit: 'g',
                color: const Color(0xFFD48220),
                icon: Icons.grain_rounded,
              ),
              Container(width: 1, height: 32, color: const Color(0xFFE2EBE5)),
              _buildMacroItem(
                label: 'ไขมัน (F)',
                doubleValue: totalFat,
                unit: 'g',
                color: const Color(0xFFC74848),
                icon: Icons.water_drop_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroItem({
    required String label,
    required double doubleValue,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6F7A72),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: doubleValue),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOutCubic,
          builder: (context, val, _) {
            return Text(
              '${val.toStringAsFixed(1)}$unit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            );
          },
        ),
      ],
    );
  }
}
