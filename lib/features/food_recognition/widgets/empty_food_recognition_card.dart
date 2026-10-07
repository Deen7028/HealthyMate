import 'package:flutter/material.dart';

class EmptyFoodRecognitionCard extends StatelessWidget {
  final bool hasApiKey;
  final String? errorMessage;
  final Color primaryColor;
  final VoidCallback onAddNewItem;
  final VoidCallback onOpenApiKeyDialog;

  const EmptyFoodRecognitionCard({
    super.key,
    required this.hasApiKey,
    this.errorMessage,
    required this.primaryColor,
    required this.onAddNewItem,
    required this.onOpenApiKeyDialog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAE6)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline_rounded,
              size: 28,
              color: Colors.amber.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasApiKey
                ? 'ไม่สามารถจำแนกรายการของกินจากภาพนี้ได้'
                : 'ยังไม่ได้ตั้งค่า Google Gemini API Key',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3830),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            !hasApiKey
                ? 'กรุณากดปุ่ม "ตั้งค่า Gemini API Key" เพื่อให้ AI ช่วยสแกนและวิเคราะห์สารอาหารอัตโนมัติ หรือกด "เพิ่มเมนูอาหาร" เพื่อระบุด้วยตนเอง'
                : (errorMessage != null && errorMessage!.isNotEmpty)
                    ? '$errorMessage\nคุณสามารถกดปุ่ม "เพิ่มเมนูอาหาร" เพื่อระบุข้อมูลด้วยตนเอง'
                    : 'ภาพถ่ายอาจมีแสงสะท้อน มืดเกินไป หรือไม่ชัดเจน\nคุณสามารถกดปุ่ม "เพิ่มเมนูอาหาร" ด้านล่างเพื่อระบุรายการอาหารและโภชนาการได้ทันที',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF7A867E),
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: onAddNewItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'เพิ่มเมนูอาหาร',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onOpenApiKeyDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(
                    color: primaryColor.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(Icons.vpn_key_rounded, size: 16),
                label: const Text(
                  'ตั้งค่า Gemini API Key',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
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
