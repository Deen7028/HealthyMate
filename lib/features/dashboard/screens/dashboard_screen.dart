import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/health_calculator/state/health_calculator_state.dart';

class DashboardScreen extends StatelessWidget {
  final HealthCalculatorState state;
  final VoidCallback onNavigateToCalculator;

  const DashboardScreen({
    super.key,
    required this.state,
    required this.onNavigateToCalculator,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting & Profile Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สวัสดี, ${state.currentUser.sFullName}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'HealthyMate Dashboard',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppTheme.primaryGreenLight,
                        child: const Icon(Icons.person, color: AppTheme.primaryGreen),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Synced Status Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E6339), Color(0xFF457C52)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'เป้าหมายพลังงานประจำวัน',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ซิงก์ล่าสุด',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${state.tdee.toInt()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'kcal / วัน (TDEE)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'เป้าหมายคงน้ำหนัก: ${state.targets.maintain} kcal | ลดไขมัน: ${state.targets.fatLoss} kcal',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Stats Grid
                  const Text(
                    'สถิติสุขภาพของคุณ',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      _buildStatCard(
                        title: 'น้ำหนักปัจจุบัน',
                        value: '${state.weight} กก.',
                        subtitle: 'ส่วนสูง ${state.height.toInt()} ซม.',
                        icon: Icons.monitor_weight_outlined,
                      ),
                      _buildStatCard(
                        title: 'ดัชนีมวลกาย (BMI)',
                        value: state.bmi.toStringAsFixed(1),
                        subtitle: state.bmiCategory.badgeText,
                        icon: Icons.accessibility_new_rounded,
                        valueColor: state.bmiCategory.color,
                      ),
                      _buildStatCard(
                        title: 'อัตราเผาผลาญ (BMR)',
                        value: '${state.bmr.toInt()} kcal',
                        subtitle: 'พลังงานขณะพัก',
                        icon: Icons.hotel_outlined,
                      ),
                      _buildStatCard(
                        title: 'ระดับกิจกรรม',
                        value: state.activityLevel.title,
                        subtitle: 'ตัวคูณ x${state.activityLevel.multiplier}',
                        icon: Icons.directions_run_rounded,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action to Recalculate
                  InkWell(
                    onTap: onNavigateToCalculator,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.subtleSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.edit_note_rounded, color: AppTheme.primaryGreen),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'ปรับเปลี่ยนหรือคำนวณค่าสุขภาพใหม่',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Icon(icon, size: 18, color: AppTheme.textTertiary),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: valueColor ?? AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
