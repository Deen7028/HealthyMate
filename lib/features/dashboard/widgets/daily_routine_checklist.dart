// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์แดชบอร์ดสรุปสุขภาพและเป้าหมาย (daily routine checklist)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';

/// การ์ดแสดงรายการเช็คลิสต์กิจวัตรประจำวัน (Daily Routine Checklist Widget)
class DailyRoutineChecklist extends StatelessWidget {
  final List<DailyChecklistItem> items;
  final Function(String id, bool isChecked) onToggleItem;
  final VoidCallback? onViewAllTap;

  const DailyRoutineChecklist({
    super.key,
    required this.items,
    required this.onToggleItem,
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = items.where((i) => i.isCompleted).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title & "เสร็จสิ้น X/Y" Pill Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: onViewAllTap,
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    const Text(
                      'กิจวัตรประจำวัน',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C2819),
                      ),
                    ),
                    if (onViewAllTap != null) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFF5A6559)),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'เสร็จสิ้น $completedCount/${items.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A6559),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Checklist Items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildChecklistCard(item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistCard(DailyChecklistItem item) {
    final isChecked = item.isCompleted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onToggleItem(item.id, !isChecked),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isChecked ? const Color(0xFFF4F8F3) : const Color(0xFFF8FAF7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isChecked ? const Color(0xFFD0E0CE) : const Color(0xFFE8ECE7),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox Box
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isChecked ? const Color(0xFF2E5327) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isChecked ? const Color(0xFF2E5327) : const Color(0xFF9EA89C),
                    width: 2,
                  ),
                ),
                child: isChecked
                    ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isChecked ? const Color(0xFF2E5327) : const Color(0xFF1C2819),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF768275),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
