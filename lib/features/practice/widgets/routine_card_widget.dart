import 'package:flutter/material.dart';

enum RoutineButtonType { workout, stepAdd, timer, singleCheck }

class RoutineCardWidget extends StatelessWidget {
  final Map<String, dynamic> routine;
  final IconData icon;
  final String title;
  final double targetVal;
  final String unitText;
  final double currentVal;
  final bool isWorkoutRoutine;
  final int percent;
  final double progressRatio;
  final Widget actionButton;
  final Widget threeDotsMenu;
  final Color cardColor;

  const RoutineCardWidget({
    super.key,
    required this.routine,
    required this.icon,
    required this.title,
    required this.targetVal,
    required this.unitText,
    required this.currentVal,
    required this.isWorkoutRoutine,
    required this.percent,
    required this.progressRatio,
    required this.actionButton,
    required this.threeDotsMenu,
    this.cardColor = const Color(0xFF2E5327),
  });

  String _formatValue(double val) =>
      val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E9E0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: cardColor.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, color: cardColor, size: 22),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1E281F),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$percent%',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: cardColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    if (isWorkoutRoutine) ...[
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 12,
                                  color: Colors.orange.shade800,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Auto-GPS Sync',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'เป้าหมาย: ${_formatValue(targetVal)} $unitText',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        'เป้าหมายประจำวัน: ${_formatValue(targetVal)} $unitText',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  actionButton,
                  threeDotsMenu,
                ],
              ),
            ],
          ),


          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ความคืบหน้า',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                '${_formatValue(currentVal)} / ${_formatValue(targetVal)} $unitText ($percent%)',
                style: TextStyle(
                  fontSize: 11.5,
                  color: cardColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 7,
              backgroundColor: cardColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                cardColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
