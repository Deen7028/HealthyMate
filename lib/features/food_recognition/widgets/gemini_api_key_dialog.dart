import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';

class GeminiApiKeyDialog extends StatefulWidget {
  final int userId;
  final String initialKey;
  final ValueChanged<String> onSaved;

  const GeminiApiKeyDialog({
    super.key,
    required this.userId,
    required this.initialKey,
    required this.onSaved,
  });

  static Future<void> show(BuildContext context, {required int userId, required String currentKey, required ValueChanged<String> onSaved}) {
    return showDialog(
      context: context,
      builder: (ctx) => GeminiApiKeyDialog(
        userId: userId,
        initialKey: currentKey,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<GeminiApiKeyDialog> createState() => _GeminiApiKeyDialogState();
}

class _GeminiApiKeyDialogState extends State<GeminiApiKeyDialog> {
  late final TextEditingController _keyCtrl;
  bool _obscureText = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController(text: widget.initialKey);
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

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
            content: Text(key.isEmpty ? 'ลบ API Key เรียบร้อยแล้ว' : 'บันทึก Gemini API Key เรียบร้อยแล้ว'),
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.vpn_key_rounded, color: primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google Gemini API Key',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E2822),
                          ),
                        ),
                        Text(
                          'สำหรับวิเคราะห์รูปภาพอาหารด้วย AI Vision จริง',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF8A958E)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF8A958E)),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'นำ API Key จาก Google AI Studio มาวางที่นี่ ระบบจะใช้โมเดล Gemini 1.5 Flash ในการอ่านภาพถ่ายอาหารจริงของคุณโดยตรง',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF5A6559), height: 1.4),
              ),
              const SizedBox(height: 14),

              // API Key Input
              TextFormField(
                controller: _keyCtrl,
                obscureText: _obscureText,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1E2822)),
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
                  hintText: 'AIzaSy...',
                  filled: true,
                  fillColor: const Color(0xFFF7F9F8),
                  prefixIcon: const Icon(Icons.key_rounded, size: 18, color: Color(0xFF8A958E)),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF8A958E)),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE4E9E6))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: primaryColor, width: 1.6)),
                ),
              ),

              const SizedBox(height: 10),
              Row(
                children: const [
                  Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF8A958E)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'หากเว้นว่างไว้ ระบบจะใช้ Local Engine สำรองอัตโนมัติ',
                      style: TextStyle(fontSize: 11, color: Color(0xFF8A958E)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFE0E5E2)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ยกเลิก', style: TextStyle(color: Color(0xFF6F7A72))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('บันทึก Key', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
