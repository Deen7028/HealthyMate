// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์การวิเคราะห์อาหารจากรูปภาพและข้อมูลโภชนาการ (food recognition result sheet items)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'food_recognition_result_sheet.dart';

extension _FoodRecognitionResultSheetItems on _FoodRecognitionResultSheetState {
  List<Widget> _buildDetectedFoodItems(
    bool isDark,
    Color primaryColor,
    Color textPrimary,
  ) => [
    // Multi-item Food List Section Header
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'เมนูที่ตรวจพบในภาพ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_result.items.length} รายการ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: _addNewItem,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text(
            'เพิ่มเมนู',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    ),
    const SizedBox(height: 10),

    // Items List
    if (_result.items.isEmpty)
      EmptyFoodRecognitionCard(
        hasApiKey: _result.hasApiKey,
        errorMessage: _result.errorMessage,
        primaryColor: primaryColor,
        onAddNewItem: _addNewItem,
        onOpenApiKeyDialog: _openApiKeyDialog,
      )
    else
      ..._result.items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return FadeSlideEntrance(
          delayIndex: index,
          child: DetectedFoodItemCard(
            item: item,
            onEdit: () => _editItem(index),
            onDelete: () => _removeItem(index),
          ),
        );
      }),
  ];
}
