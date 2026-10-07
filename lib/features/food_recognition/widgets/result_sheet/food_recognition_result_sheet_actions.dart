part of 'food_recognition_result_sheet.dart';

// ส่วนขยายจัดการ Action และการโต้ตอบของผู้ใช้ใน Result Sheet (Result Sheet Actions Extension)
extension _FoodRecognitionResultSheetActions
    on _FoodRecognitionResultSheetState {
  // ฟังก์ชัน: โหลดค่าน้ำหนักของผู้ใช้สำหรับคำนวณการเผาผลาญ (Load User Weight)
  Future<void> _loadUserWeight() async {
    // 1. ดึงข้อมูลผู้ใช้ปัจจุบันจาก SQLite
    final user = await AppDatabase.instance.getCurrentUser();
    final weight = user?.nWeight ?? 0.0;

    // 2. อัปเดตค่าน้ำหนักเข้าสู่ State
    if (weight > 0 && mounted) {
      setState(() {
        _userWeight = weight;
      });
    }
  }

  // ฟังก์ชัน: เปิด Dialog แก้ไขข้อมูลอาหารในรายการ (Edit Item)
  void _editItem(int index) {
    showDialog(
      context: context,
      builder: (context) => EditFoodItemDialog(
        item: _result.items[index],
        onSave: (updated) {
          setState(() {
            _result.items[index] = updated;
          });
        },
      ),
    );
  }

  // ฟังก์ชัน: เพิ่มรายการอาหารใหม่เข้าไปในมื้ออาหาร (Add New Item)
  void _addNewItem() {
    final newItem = DetectedFoodItem(
      id: 'food_${DateTime.now().millisecondsSinceEpoch}',
      name: 'รายการอาหารเพิ่มเติม',
      calories: 100,
      protein: 5.0,
      carbs: 15.0,
      fat: 2.0,
      servingSize: '1 ที่',
    );
    showDialog(
      context: context,
      builder: (context) => EditFoodItemDialog(
        item: newItem,
        onSave: (savedItem) {
          setState(() {
            _result.items.add(savedItem);
          });
        },
      ),
    );
  }

  // ฟังก์ชัน: ลบรายการอาหารออกจากมื้อ (Remove Item)
  void _removeItem(int index) {
    setState(() {
      _result.items.removeAt(index);
    });
  }

  // ฟังก์ชัน: เปิด Dialog สำหรับตั้งค่า Gemini API Key (Open API Key Dialog)
  Future<void> _openApiKeyDialog() async {
    final user = await AppDatabase.instance.getCurrentUser();
    final userId = user?.nUserId;
    if (userId == null) return;
    final currentKey = await AppDatabase.instance.getGeminiApiKey(userId);
    if (mounted) {
      GeminiApiKeyDialog.show(
        context,
        userId: userId,
        currentKey: currentKey,
        onSaved: (_) {},
      );
    }
  }
}
