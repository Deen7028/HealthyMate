import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

class TermsPrivacySheets {
  static void showTermsBottomSheet({
    required BuildContext context,
    required VoidCallback onAccept,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'เงื่อนไขการให้บริการ (Terms of Service)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: const [
                        Text(
                          '1. การยอมรับข้อตกลง\nการลงทะเบียนใช้งาน HealthyMate หมายถึงคุณยอมรับข้อตกลงและเงื่อนไขการใช้งานแอปพลิเคชันนี้ทั้งหมด\n\n'
                          '2. การใช้งานข้อมูลส่วนบุคคล\nผู้ใช้จะต้องให้ข้อมูลที่เป็นความจริงและถูกต้อง เพื่อให้ระบบคำนวณค่า BMR, TDEE และโภชนาการได้อย่างแม่นยำ\n\n'
                          '3. ความปลอดภัยของบัญชี\nผู้ใช้มีหน้าที่เก็บรักษารหัสผ่านของตนเองเป็นความลับ และต้องแจ้งให้ทีมงานทราบทันทีหากพบการเข้าถึงโดยไม่ได้รับอนุญาต\n\n'
                          '4. คำเตือนด้านสุขภาพ\nข้อมูลและการคำนวณใน HealthyMate เป็นคำแนะนำเบื้องต้นเท่านั้น ไม่สามารถทดแทนคำแนะนำทางการแพทย์หรือวิชาชีพได้',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        onAccept();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('ยอมรับเงื่อนไขการให้บริการ'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void showPrivacyBottomSheet({
    required BuildContext context,
    required VoidCallback onAccept,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'นโยบายความเป็นส่วนตัว (Privacy Policy)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: const [
                        Text(
                          '1. การเก็บรวบรวมข้อมูลสุขภาพและพิกัด GPS\nHealthyMate รวบรวมข้อมูลส่วนสูง น้ำหนัก อายุ และบันทึกกิจกรรม พร้อมตำแหน่ง GPS (เพื่อคำนวณการเดิน/วิ่ง) ด้วยความยินยอมของคุณ\n\n'
                          '2. การจัดเก็บและการปกป้องข้อมูล\nข้อมูลของคุณจะถูกเข้ารหัสและจัดเก็บในระบบอย่างปลอดภัยตามมาตรฐานความปลอดภัยข้อมูลสุขภาพ\n\n'
                          '3. สิทธิของผู้ใช้งาน\nคุณมีสิทธิในการเข้าถึง แก้ไข หรือลบข้อมูลส่วนบุคคลของคุณได้ตลอดเวลาผ่านเมนูตั้งค่าโปรไฟล์',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        onAccept();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('ยอมรับนโยบายความเป็นส่วนตัว'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
