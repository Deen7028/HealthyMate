part of 'calendar_strip_widget.dart';

extension _CalendarStripDayItem on CalendarStripWidget {
  /// build UI ของแต่ละวันใน calendar strip
  Widget _buildDayItem(
    String day,
    String date,
    bool isSelected,
    bool isPast,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? darkGreen
                : (isDark ? const Color(0xFFA0ACA0) : Colors.grey),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? darkGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              date,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.greenAccent
                : (isPast
                      ? darkGreen
                      : (isDark
                            ? const Color(0xFF3B4D41)
                            : Colors.grey.shade300)),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
