part of 'food_recognition_result_sheet.dart';

extension _FoodRecognitionResultSheetBody on _FoodRecognitionResultSheetState {
  Widget _buildScrollableBody(
    bool isDark,
    Color surfaceBg,
    Color borderColor,
    Color primaryColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนหัว ของหน้าต่างแสดงผลการวิเคราะห์อาหาร
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // รูปภาพอาหารที่วิเคราะห์แล้ว
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 88,
                    height: 88,
                    color: surfaceBg,
                    child: File(_result.imagePath).existsSync()
                        ? Image.file(File(_result.imagePath), fit: BoxFit.cover)
                        : Icon(
                            Icons.restaurant_rounded,
                            size: 36,
                            color: textSecondary,
                          ),
                  ),
                ),
                const SizedBox(width: 14),

                // ส่วนเลื่อนลง
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เลือกประเภทมื้ออาหาร',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: MealCategory.values.map((cat) {
                          final isSel = _result.category == cat;
                          return ChoiceChip(
                            label: Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSel ? Colors.white : textSecondary,
                              ),
                            ),
                            selected: isSel,
                            selectedColor: isDark
                                ? const Color(0xFF2E5327)
                                : primaryColor,
                            backgroundColor: surfaceBg,
                            side: BorderSide(
                              color: isSel
                                  ? (isDark
                                        ? AppTheme.primaryLightGreen
                                        : primaryColor)
                                  : borderColor,
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            showCheckmark: false,
                            onSelected: (val) {
                              if (val) setState(() => _result.category = cat);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ส่วนแสดงผลรวมสารอาหาร
            FoodNutritionSummaryCard(
              totalCalories: _result.totalCalories,
              totalProtein: _result.totalProtein,
              totalCarbs: _result.totalCarbs,
              totalFat: _result.totalFat,
              primaryColor: primaryColor,
            ),

            const SizedBox(height: 16),

            // ส่วนแสดงคำแนะนำการออกกำลังกาย
            BurnItOffAdvisorCard(
              totalCalories: _result.totalCalories,
              userWeight: _userWeight,
              primaryColor: primaryColor,
            ),

            const SizedBox(height: 22),

            ..._buildDetectedFoodItems(isDark, primaryColor, textPrimary),
          ],
        ),
      ),
    );
  }
}
