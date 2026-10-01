part of 'gemini_api_key_dialog.dart';

extension _GeminiApiKeyDialogSave on _GeminiApiKeyDialogState {
  Future<void> _handleSave() async {
    final key = _keyCtrl.text.trim();
    setState(() => _isSaving = true);
    try {
      await AppDatabase.instance.saveGeminiApiKey(widget.userId, key);
      widget.onSaved(key);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              key.isEmpty
                  ? 'ลบ API Key เรียบร้อยแล้ว'
                  : 'บันทึก Gemini API Key เรียบร้อยแล้ว',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving api key: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึก Key: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
