part of 'routine_step_style.dart';

extension RoutineStepStyleMultipleTimes on _RoutineStepStyleState {
  Widget _buildMultipleTimesMode(
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ..._multipleTimes.asMap().entries.map((entry) {
              final idx = entry.key;
              final timeStr = entry.value;
              return InkWell(
                onTap: () async {
                  TimeOfDay initialTime = const TimeOfDay(hour: 8, minute: 0);
                  final match = RegExp(
                    r'(\d{1,2}):(\d{2})',
                  ).firstMatch(timeStr);
                  if (match != null) {
                    initialTime = TimeOfDay(
                      hour: int.parse(match.group(1)!),
                      minute: int.parse(match.group(2)!),
                    );
                  }
                  final picked = await _pickTime(initialTime);
                  if (picked != null) {
                    final formattedHour = picked.hour.toString().padLeft(
                      2,
                      '0',
                    );
                    final formattedMinute = picked.minute.toString().padLeft(
                      2,
                      '0',
                    );
                    setState(() {
                      _multipleTimes[idx] = '$formattedHour:$formattedMinute';
                      _updateControllerText();
                    });
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.btnColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.btnColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$timeStr น.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: widget.btnColor,
                        ),
                      ),
                      if (_multipleTimes.length > 1) ...[
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _multipleTimes.removeAt(idx);
                              _updateControllerText();
                            });
                          },
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: widget.btnColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            InkWell(
              onTap: () async {
                final picked = await _pickTime(
                  const TimeOfDay(hour: 12, minute: 0),
                );
                if (picked != null) {
                  final formattedHour = picked.hour.toString().padLeft(2, '0');
                  final formattedMinute = picked.minute.toString().padLeft(
                    2,
                    '0',
                  );
                  setState(() {
                    _multipleTimes.add('$formattedHour:$formattedMinute');
                    _updateControllerText();
                  });
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2E3D34)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: textPrimary),
                    const SizedBox(width: 2),
                    Text(
                      'เพิ่มเวลา',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
