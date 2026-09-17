import 'package:flutter/material.dart';

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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ข้อมูลส่วนตัว',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2822),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('ชื่อเต็ม', fullName),
            _buildInfoRow('อีเมล', email),
            _buildInfoRow('เพศ', gender == 'female' ? 'หญิง' : 'ชาย'),
            _buildInfoRow('อายุ', '$age ปี'),
            _buildInfoRow('ส่วนสูง', '$height ซม.'),
            _buildInfoRow('น้ำหนัก', '$weight กก.'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E6339),
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6F7A72), fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E2822),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
