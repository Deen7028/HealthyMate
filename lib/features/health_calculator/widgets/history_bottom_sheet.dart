import 'package:flutter/material.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/health_calculator/models/health_record_model.dart';

class HistoryBottomSheet extends StatelessWidget {
  final List<TbHealthRecord> historyList;
  final ValueChanged<int> onDeleteRecord;

  const HistoryBottomSheet({
    super.key,
    required this.historyList,
    required this.onDeleteRecord,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: AppTheme.scaffoldBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.history_rounded,
                      color: AppTheme.primaryGreen,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ประวัติการคำนวณย้อนหลัง',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppTheme.borderLight),

          // Content
          Expanded(
            child: historyList.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: historyList.length + 2,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildTrendGraphCard();
                      } else if (index == 1) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 20, bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'รายการบันทึกสุขภาพล่าสุด',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                'ทั้งหมด ${historyList.length} รายการ',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      final record = historyList[index - 2];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildHistoryItem(context, record),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          SizedBox(height: 12),
          Text(
            'ยังไม่มีประวัติการคำนวณ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'เมื่อคุณกดบันทึกข้อมูล ระบบจะซิงก์เข้าฐานข้อมูลและแสดงแนวโน้มที่นี่',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendGraphCard() {
    final sortedRecords = List<TbHealthRecord>.from(historyList).reversed.toList();
    final weights = sortedRecords.map((r) => r.nWeight).toList();
    final firstWeight = weights.isNotEmpty ? weights.first : 0.0;
    final latestWeight = weights.isNotEmpty ? weights.last : 0.0;
    final diff = latestWeight - firstWeight;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'แนวโน้มการเปลี่ยนแปลงน้ำหนัก',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'เปรียบเทียบจาก ${sortedRecords.length} บันทึก',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: diff <= 0 ? const Color(0xFFE8F3EB) : const Color(0xFFFFF0E8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  diff <= 0
                      ? '${diff.toStringAsFixed(1)} กก. (ลดลง)'
                      : '+${diff.toStringAsFixed(1)} กก. (เพิ่มขึ้น)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: diff <= 0 ? AppTheme.primaryGreen : const Color(0xFFD35400),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _WeightChartPainter(weights: weights),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'เริ่มต้น: ${firstWeight.toStringAsFixed(1)} กก.',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Text(
                'ปัจจุบัน: ${latestWeight.toStringAsFixed(1)} กก.',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, TbHealthRecord record) {
    final dateStr =
        '${record.dtRecordedAt.day}/${record.dtRecordedAt.month}/${record.dtRecordedAt.year}  ${record.dtRecordedAt.hour.toString().padLeft(2, '0')}:${record.dtRecordedAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  record.bmiCategoryObj.badgeText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMetricPill('น้ำหนัก', '${record.nWeight} กก.'),
              const SizedBox(width: 8),
              _buildMetricPill('ส่วนสูง', '${record.nHeight.toInt()} ซม.'),
              const SizedBox(width: 8),
              _buildMetricPill('BMI', record.nBmi.toStringAsFixed(1)),
              const SizedBox(width: 8),
              _buildMetricPill('TDEE', '${record.nTdee.toInt()} kcal'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'กิจกรรม: ${record.activityLevelTitle ?? "ปกติ"}',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.textTertiary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => onDeleteRecord(record.nRecordId),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: AppTheme.subtleSurface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<double> weights;

  _WeightChartPainter({required this.weights});

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.isEmpty) return;

    final linePaint = Paint()
      ..color = AppTheme.primaryGreen
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primaryGreen.withValues(alpha: 0.25),
          AppTheme.primaryGreen.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = AppTheme.primaryGreen
      ..style = PaintingStyle.fill;

    final dotInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = AppTheme.borderLight
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (weights.length == 1) {
      final point = Offset(size.width / 2, size.height / 2);
      canvas.drawCircle(point, 6, dotPaint);
      canvas.drawCircle(point, 3, dotInnerPaint);
      return;
    }

    final minW = weights.reduce((a, b) => a < b ? a : b) - 1.0;
    final maxW = weights.reduce((a, b) => a > b ? a : b) + 1.0;
    final range = (maxW - minW) == 0 ? 1.0 : (maxW - minW);

    final points = <Offset>[];
    final dx = size.width / (weights.length - 1);

    for (int i = 0; i < weights.length; i++) {
      final x = i * dx;
      final normalized = (weights[i] - minW) / range;
      final y = size.height - (normalized * (size.height - 20) + 10);
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final cx = (p0.dx + p1.dx) / 2;
      path.cubicTo(cx, p0.dy, cx, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    for (final pt in points) {
      canvas.drawCircle(pt, 5, dotPaint);
      canvas.drawCircle(pt, 2.5, dotInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    return oldDelegate.weights != weights;
  }
}
