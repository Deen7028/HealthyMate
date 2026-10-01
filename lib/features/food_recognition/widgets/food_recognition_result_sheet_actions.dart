part of 'food_recognition_result_sheet.dart';

extension _FoodRecognitionResultSheetActions
    on _FoodRecognitionResultSheetState {
  Future<void> _loadUserWeight() async {
    final user = await AppDatabase.instance.getCurrentUser();
    final weight = user?.nWeight ?? 0.0;
    if (weight > 0 && mounted) {
      setState(() {
        _userWeight = weight;
      });
    }
  }

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

  void _removeItem(int index) {
    setState(() {
      _result.items.removeAt(index);
    });
  }

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
