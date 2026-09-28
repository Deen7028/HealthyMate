import 'package:flutter/material.dart';
import 'package:healthymate/core/utils/health_calculator.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';
import 'package:healthymate/features/health_calculator/models/activity_level.dart';

class DashboardHealthSummaryCard extends StatelessWidget {
  final TbUser? user;
  final TbHealthRecord? latestRecord;
  final DateTime now;
  final double totalCaloriesBurned;
  final int todayNutritionCalories;
  final int todayScannedFoodCount;
  final List<Map<String, dynamic>> todayNutritionLogs;
  final VoidCallback? onNavigateToCalculator;
  final VoidCallback? onOpenFoodScanner;
  final Color primaryGreen;
  final Color darkGreen;

  const DashboardHealthSummaryCard({
    super.key,
    required this.user,
    required this.latestRecord,
    required this.now,
    required this.totalCaloriesBurned,
    this.todayNutritionCalories = 0,
    this.todayScannedFoodCount = 0,
    this.todayNutritionLogs = const [],
    this.onNavigateToCalculator,
    this.onOpenFoodScanner,
    this.primaryGreen = const Color(0xFF0F9C58),
    this.darkGreen = const Color(0xFF006432),
  });

  String _formatNumber(double val) =>
      val >= 1000 ? val.toStringAsFixed(0) : val.toStringAsFixed(val.truncateToDouble() == val ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final weight = latestRecord?.nWeight ?? user?.nWeight ?? 0.0;
    final height = latestRecord?.nHeight ?? user?.nHeight ?? 0.0;
    final bmi =
        latestRecord?.nBmi ??
        (weight > 0 && height > 0
            ? HealthCalculator.calculateBMI(weightKg: weight, heightCm: height)
            : 0.0);
    final bmiCategory = HealthCalculator.getBMICategory(bmi);

    final age = user?.nAge ?? 0;
    final gender = user?.genderEnum ?? Gender.male;
    final activityLevel = user?.activityLevelObj ?? ActivityLevel.options[1];

    double bmr = latestRecord?.computedBmr ?? 0.0;
    double tdee = latestRecord?.nTdee ?? 0.0;

    if (bmr <= 0 && weight > 0 && height > 0 && age > 0) {
      bmr = HealthCalculator.calculateBMR(
        gender: gender,
        weightKg: weight,
        heightCm: height,
        age: age,
      );
    }
    if (tdee <= 0 && bmr > 0) {
      tdee = HealthCalculator.calculateTDEE(
        bmr: bmr,
        activityMultiplier: activityLevel.multiplier,
      );
    }

    String lastRecordText = 'ยังไม่มีข้อมูล';
    if (latestRecord != null) {
      final diff = now.difference(latestRecord!.dtRecordedAt);
      if (diff.inMinutes < 60) {
        lastRecordText = 'คำนวณล่าสุดเมื่อ ${diff.inMinutes} นาทีที่แล้ว';
      } else if (diff.inHours < 24) {
        lastRecordText = 'คำนวณล่าสุดเมื่อ ${diff.inHours} ชม. ที่แล้ว';
      } else {
        lastRecordText = 'คำนวณล่าสุดเมื่อ ${diff.inDays} วันที่แล้ว';
      }
    }

    final burnTarget = tdee > 0 ? (tdee * 0.2).round() : 400;

    // Daily Net Energy Allowance calculation based directly on TDEE
    final double targetTdee = tdee > 0 ? tdee : 2000.0;
    final double remainingEnergyQuota = targetTdee - todayNutritionCalories;
    final double netEnergyRatio = (targetTdee > 0)
        ? (todayNutritionCalories / targetTdee).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.health_and_safety, color: darkGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ข้อมูลสุขภาพส่วนบุคคล',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            lastRecordText,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onNavigateToCalculator,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.sync, size: 15, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          'อัปเดตข้อมูล',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildStatItem(
                  'น้ำหนัก / ส่วนสูง',
                  weight > 0
                      ? '${_formatNumber(weight)} กก. | ${_formatNumber(height)} ซม.'
                      : 'ยังไม่ระบุ',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItemWithBadge(
                  'ดัชนีมวลกาย',
                  bmi > 0 ? bmi.toStringAsFixed(1) : '-',
                  bmi > 0 ? bmiCategory.badgeText : 'ยังไม่ระบุ',
                  bmi > 0 ? bmiCategory.color : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildStatItemWithWidget(
                  'BMR พลังงานพื้นฐาน',
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: bmr),
                    duration: const Duration(milliseconds: 2500),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, _) => Text(
                      bmr > 0 ? '${val.round()} kcal' : '- kcal',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  icon: Icons.bolt,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatItemWithWidget(
                  'TDEE ต้องการต่อวัน',
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: tdee),
                    duration: const Duration(milliseconds: 2500),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, _) => Text(
                      tdee > 0 ? '${val.round()} kcal' : '- kcal',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  icon: Icons.local_fire_department,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // --- ⚡ AI Food & Energy Balance Ring / Tracker Card ---
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpenFoodScanner,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryGreen.withValues(alpha: 0.08),
                      Colors.amber.shade50.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: primaryGreen.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Header + Scanner Badge + Scan Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.restaurant_rounded, size: 16, color: darkGreen),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'สมดุลแคลอรี่ประจำวัน',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.camera_alt_rounded, size: 10, color: darkGreen),
                                    const SizedBox(width: 3),
                                    Text(
                                      'AI Food Scanner',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                        color: darkGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onOpenFoodScanner != null)
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            elevation: 0.5,
                            child: InkWell(
                              onTap: onOpenFoodScanner,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: primaryGreen.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_a_photo_rounded, size: 12, color: darkGreen),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ถ่ายบันทึก',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: darkGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row 2: Animated Calorie Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: todayNutritionCalories.toDouble()),
                              duration: const Duration(milliseconds: 1500),
                              curve: Curves.easeOutCubic,
                              builder: (context, val, _) => Text(
                                '${val.round()}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: todayNutritionCalories > targetTdee
                                      ? Colors.red.shade700
                                      : darkGreen,
                                ),
                              ),
                            ),
                            Text(
                              ' / ${targetTdee.round()} kcal',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          todayScannedFoodCount > 0
                              ? 'สแกนแล้ว $todayScannedFoodCount รายการ'
                              : 'ยังไม่ได้สแกน',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: todayScannedFoodCount > 0 ? primaryGreen : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: netEnergyRatio,
                        minHeight: 8,
                        backgroundColor: Colors.black.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          todayNutritionCalories > targetTdee
                              ? Colors.redAccent
                              : (netEnergyRatio > 0.85
                                  ? Colors.orangeAccent
                                  : primaryGreen),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Row 3: Remaining Quota & Burned
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          remainingEnergyQuota >= 0
                              ? 'วันนี้กินได้อีก ${remainingEnergyQuota.round()} kcal'
                              : 'เกินโควตาพลังงาน ${(-remainingEnergyQuota).round()} kcal',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: remainingEnergyQuota >= 0
                                ? Colors.black87
                                : Colors.red.shade700,
                          ),
                        ),
                        Text(
                          'เบิร์นเพิ่ม +${totalCaloriesBurned.round()} kcal',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),

                    // Row 4: Food items preview or CTA hint
                    if (todayNutritionLogs.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: todayNutritionLogs.take(3).map((item) {
                          final name = item['sFoodName']?.toString() ?? 'อาหาร';
                          final cal = (item['nCalories'] as num?)?.toInt() ?? 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: primaryGreen.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🍽️ ', style: TextStyle(fontSize: 10)),
                                Text(
                                  name.length > 15 ? '${name.substring(0, 14)}...' : name,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '+$cal kcal',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: darkGreen,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ] else ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.touch_app_rounded, size: 12, color: primaryGreen),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'แตะที่นี่เพื่อถ่ายบันทึกอาหารด้วย AI Food Scanner',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.track_changes, color: primaryGreen),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เป้าหมายเผาผลาญจากการออกกำลังกาย',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: totalCaloriesBurned),
                        duration: const Duration(milliseconds: 2500),
                        curve: Curves.easeOutCubic,
                        builder: (context, val, _) => Text(
                          'เผาผลาญแล้ววันนี้ ${val.toStringAsFixed(0)} kcal',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$burnTarget\nkcal/วัน',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryGreen,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItemWithWidget(String title, Widget valueWidget, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
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

  Widget _buildStatItem(String title, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItemWithBadge(
    String title,
    String value,
    String badgeText,
    Color badgeColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 2,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
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
