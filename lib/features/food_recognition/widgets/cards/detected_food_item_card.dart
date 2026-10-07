import 'package:flutter/material.dart';
import 'package:healthymate/features/food_recognition/models/food_recognition_models.dart';

// วิดเจ็ตการ์ดแสดงรายการอาหารที่ตรวจพบ (Detected Food Item Card Widget)
// แสดงข้อมูลชื่ออาหาร ปริมาณ แคลอรี สารอาหาร และปุ่มแก้ไข/ลบ
class DetectedFoodItemCard extends StatelessWidget {
  final DetectedFoodItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DetectedFoodItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECE8), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Food Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F6F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fastfood_rounded,
              color: Color(0xFF4B6353),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Title & Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2822),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.servingSize} • P:${item.protein.toStringAsFixed(1)}g  C:${item.carbs.toStringAsFixed(1)}g  F:${item.fat.toStringAsFixed(1)}g',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF7A867E),
                  ),
                ),
              ],
            ),
          ),

          // Calories Badge
          Text(
            '${item.calories} kcal',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFFD65838),
            ),
          ),

          // Edit Button
          IconButton(
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: Color(0xFF6F7A72),
            ),
            visualDensity: VisualDensity.compact,
            tooltip: 'ปรับแต่งปริมาณ/ส่วนผสม',
          ),

          // Delete Button
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: Colors.redAccent,
            ),
            visualDensity: VisualDensity.compact,
            tooltip: 'ลบรายการนี้',
          ),
        ],
      ),
    );
  }
}
