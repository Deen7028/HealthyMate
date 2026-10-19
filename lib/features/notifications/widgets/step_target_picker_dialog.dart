import 'package:flutter/material.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

/// ไดอะล็อกสำหรับกำหนดเป้าหมายก้าวเดินประจำวัน (Step Target Picker Dialog)
class StepTargetPickerDialog extends StatefulWidget {
  final int nCurrentTarget;
  final ValueChanged<int> onTargetSelected;

  const StepTargetPickerDialog({
    super.key,
    required this.nCurrentTarget,
    required this.onTargetSelected,
  });

  @override
  State<StepTargetPickerDialog> createState() => _StepTargetPickerDialogState();
}

class _StepTargetPickerDialogState extends State<StepTargetPickerDialog> {
  late int _nSelectedTarget;
  late TextEditingController _customController;
  bool _isCustom = false;

  final List<int> _lstPresets = [6000, 8000, 10000, 12000];

  @override
  void initState() {
    super.initState();
    _nSelectedTarget = widget.nCurrentTarget;
    _isCustom = !_lstPresets.contains(widget.nCurrentTarget);
    _customController = TextEditingController(
      text: _isCustom ? widget.nCurrentTarget.toString() : '',
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _onPresetTapped(int nTarget) {
    setState(() {
      _nSelectedTarget = nTarget;
      _isCustom = false;
      _customController.clear();
    });
  }

  void _onSave() {
    int nFinalTarget = _nSelectedTarget;
    if (_isCustom) {
      final int? nParsed = int.tryParse(_customController.text.trim());
      if (nParsed != null && nParsed > 0) {
        nFinalTarget = nParsed;
      }
    }
    widget.onTargetSelected(nFinalTarget);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = AppTheme.getBackgroundColor(isDark);
    final Color textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final Color textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final Color borderColor = AppTheme.getBorderColor(isDark);

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_walk_rounded,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'เป้าหมายก้าวประจำวัน',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'กำหนดจำนวนก้าวสำหรับหลอดความคืบหน้า',
                        style: TextStyle(fontSize: 11.5, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _lstPresets.map((nPreset) {
                final bool isSelected = !_isCustom && _nSelectedTarget == nPreset;
                return ChoiceChip(
                  label: Text('${nPreset ~/ 1000},000 ก้าว'),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppTheme.primaryGreen : textPrimary,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppTheme.primaryGreen : borderColor,
                  ),
                  onSelected: (_) => _onPresetTapped(nPreset),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _customController,
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 14, color: textPrimary),
              decoration: InputDecoration(
                labelText: 'หรือระบุจำนวนก้าวเอง',
                hintText: 'เช่น 7500',
                suffixText: 'ก้าว',
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onTap: () {
                setState(() => _isCustom = true);
              },
              onChanged: (val) {
                if (!_isCustom) {
                  setState(() => _isCustom = true);
                }
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('ยกเลิก', style: TextStyle(color: textSecondary)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _onSave,
                  child: const Text('บันทึก'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
