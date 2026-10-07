part of 'food_recognition_result_sheet.dart';

extension _FoodRecognitionResultSheetChrome
    on _FoodRecognitionResultSheetState {
  List<Widget> _buildHeader(
    BuildContext context,
    bool isDark,
    Color primaryColor,
    Color textPrimary,
    Color textSecondary,
    Color borderColor,
  ) => [
    // Header
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ผลวิเคราะห์อาหาร AI Vision',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Text(
                  'จำแนกหลายเมนู พร้อมแจกแจงสารอาหารหลัก P/C/F',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'ตั้งค่า Gemini API Key',
            onPressed: _openApiKeyDialog,
            icon: Icon(Icons.vpn_key_outlined, color: textSecondary, size: 20),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: textSecondary),
          ),
        ],
      ),
    ),
    Divider(height: 1, color: borderColor),
  ];

  Widget _buildSaveFooter(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(top: BorderSide(color: borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF2E5327) : primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          onPressed: (_isSaving || _result.items.isEmpty)
              ? null
              : _saveMealToDatabase,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  _result.items.isEmpty
                      ? Icons.playlist_add_rounded
                      : Icons.bookmark_added_rounded,
                  color: Colors.white,
                ),
          label: Text(
            _isSaving
                ? 'กำลังบันทึกข้อมูล...'
                : _result.items.isEmpty
                ? 'กรุณาเพิ่มรายการอาหารก่อนบันทึก'
                : 'บันทึกมื้อ${_result.category.label} (${_result.totalCalories} kcal)',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
