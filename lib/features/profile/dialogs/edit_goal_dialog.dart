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
  late final TextEditingController _progressCtrl;
  late double _tempProgress;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _timeCtrl = TextEditingController(text: widget.initialRemainingText);
    _tempProgress = widget.initialProgress;
    _progressCtrl = TextEditingController(text: (_tempProgress * 100).toInt().toString());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _timeCtrl.dispose();
    _progressCtrl.dispose();
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ความคืบหน้า:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(
                  width: 70,
                  height: 36,
                  child: TextField(
                    controller: _progressCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      suffixText: '%',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed >= 0 && parsed <= 100) {
                        setState(() {
                          _tempProgress = parsed / 100.0;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            Slider(
              value: _tempProgress.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (val) {
                setState(() {
                  _tempProgress = val;
                  _progressCtrl.text = (val * 100).toInt().toString();
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
            backgroundColor: Theme.of(context).colorScheme.primary,
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
