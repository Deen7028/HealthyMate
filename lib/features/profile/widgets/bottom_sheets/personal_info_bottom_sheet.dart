import 'package:flutter/material.dart';
import 'package:healthymate/core/services/theme_service.dart';
//BottomSheet สำหรับแสดงข้อมูลส่วนตัว
class PersonalInfoBottomSheet extends StatelessWidget {
  final String fullName;
  final String email;
  final String gender;
  final int age;
  final double height;
  final double weight;
  final VoidCallback onEditTap;

  const PersonalInfoBottomSheet({
    super.key,
    required this.fullName,
    required this.email,
    required this.gender,
    required this.age,
    required this.height,
    required this.weight,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ข้อมูลส่วนตัว',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E2822),
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('ชื่อเต็ม', fullName.trim().isNotEmpty ? fullName : 'ยังไม่ระบุ', isDark),
              _buildInfoRow('อีเมล', email.trim().isNotEmpty ? email : 'ยังไม่ระบุ', isDark),
              _buildInfoRow('เพศ', gender == 'female' ? 'หญิง' : 'ชาย', isDark),
              _buildInfoRow('อายุ', age > 0 ? '$age ปี' : 'ยังไม่ระบุ', isDark),
              _buildInfoRow('ส่วนสูง', height > 0 ? '${height.toStringAsFixed(0)} ซม.' : 'ยังไม่ระบุ', isDark),
              _buildInfoRow('น้ำหนัก', weight > 0 ? '${weight.toStringAsFixed(1)} กก.' : 'ยังไม่ระบุ', isDark),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    onEditTap();
                  },
                  child: const Text('แก้ไขข้อมูล', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFFA0ACA0) : const Color(0xFF6F7A72),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E2822),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
