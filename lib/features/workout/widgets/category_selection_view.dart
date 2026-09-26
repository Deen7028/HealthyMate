import 'package:flutter/material.dart';
import 'package:healthymate/features/workout/models/workout_models.dart';
import 'package:healthymate/features/workout/pages/workout_history_page.dart';

class CategorySelectionView extends StatelessWidget {
  final WorkoutCategory selectedCategory;
  final int userId;
  final ValueChanged<WorkoutCategory> onSelectCategory;

  const CategorySelectionView({
    super.key,
    required this.selectedCategory,
    required this.userId,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'เลือกหมวดหมู่การออกกำลังกาย',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1C2819),
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'เลือกประเภทกิจกรรมก่อนเริ่มตรวจวัดและคำนวณแคลอรี',
                          style: TextStyle(fontSize: 13.5, color: Color(0xFF677366)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // ปุ่มไอคอนประวัติการออกกำลังกาย มุมขวาบน
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => WorkoutHistoryPage(userId: userId),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E9E0), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Tooltip(
                        message: 'ประวัติการออกกำลังกาย',
                        child: Icon(
                          Icons.history_rounded,
                          color: Color(0xFF2E5327),
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ...WorkoutCategory.categories.map((category) {
                final isSelected = selectedCategory.id == category.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    onTap: () => onSelectCategory(category),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF2E5327) : const Color(0xFFE2E9E0),
                          width: isSelected ? 2 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F3EB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(category.icon, color: const Color(0xFF2E5327), size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1C2819),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  category.subtitle,
                                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF677366)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF8B9889)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
