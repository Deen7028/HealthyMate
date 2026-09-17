import 'package:flutter/material.dart';

class EditGoalDialog extends StatefulWidget {
  final String initialTitle;
  final double initialProgress;
  final String initialRemainingText;
  final Future<void> Function(String title, double progress, String remainingText) onSave;

  const EditGoalDialog({
    super.key,
    required this.initialTitle,
    required this.initialProgress,
    required this.initialRemainingText,
    required this.onSave,
  });

  @override
  State<EditGoalDialog> createState() => _EditGoalDialogState();
}

class _EditGoalDialogState extends State<EditGoalDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _timeCtrl;
  late double _tempProgress;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _timeCtrl = TextEditingController(text: widget.initialRemainingText);
    _tempProgress = widget.initialProgress;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'แก้ไขเป้าหมายหลัก',
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E2822)),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: 'ชื่อเป้าหมาย',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ความคืบหน้า: ${(_tempProgress * 100).toInt()}%',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _tempProgress,
              min: 0.0,
              max: 1.0,
              divisions: 20,
              activeColor: const Color(0xFF2E6339),
              onChanged: (val) {
                setState(() {
                  _tempProgress = val;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _timeCtrl,
              decoration: InputDecoration(
                labelText: 'ระยะเวลาที่เหลือ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E6339),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            final newTitle = _titleCtrl.text.trim().isNotEmpty
                ? _titleCtrl.text.trim()
                : widget.initialTitle;
            final newRemaining = _timeCtrl.text.trim().isNotEmpty
                ? _timeCtrl.text.trim()
                : widget.initialRemainingText;

            await widget.onSave(newTitle, _tempProgress, newRemaining);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
