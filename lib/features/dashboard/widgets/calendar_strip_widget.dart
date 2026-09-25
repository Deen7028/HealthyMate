import 'package:flutter/material.dart';

class CalendarStripWidget extends StatelessWidget {
  final DateTime now;
  final String thaiMonthName;
  final int workoutCount;
  final double totalDistanceKm;
  final double totalCaloriesBurned;
  final Color darkGreen;

  const CalendarStripWidget({
    super.key,
    required this.now,
    required this.thaiMonthName,
    required this.workoutCount,
    required this.totalDistanceKm,
    required this.totalCaloriesBurned,
    this.darkGreen = const Color(0xFF006432),
  });

  @override
  Widget build(BuildContext context) {
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));
    const dayLabels = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.', 'ส.', 'อา.'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'สัปดาห์นี้ • $thaiMonthName ${now.year + 543}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      '🏃 ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade400,
                      ),
                    ),
                    Text(
                      '$workoutCount ครั้งออกกำลังกาย',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Days Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final isToday =
                  days[i].day == now.day &&
                  days[i].month == now.month &&
                  days[i].year == now.year;
              final isPast = days[i].isBefore(
                DateTime(now.year, now.month, now.day),
              );
              return _buildDayItem(
                dayLabels[i],
                '${days[i].day}',
                isToday,
                isPast,
              );
            }),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.fitness_center,
                    size: 14,
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ออกกำลังกายแล้ว $workoutCount ครั้ง | ${totalDistanceKm.toStringAsFixed(1)} กม.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${totalCaloriesBurned.toStringAsFixed(0)} kcal',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayItem(String day, String date, bool isSelected, bool isPast) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? darkGreen : Colors.grey,
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
                color: isSelected ? Colors.white : Colors.black87,
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
                : (isPast ? darkGreen : Colors.grey.shade300),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
