import 'package:healthymate/core/utils/health_calculator.dart';

/// Data Model สำหรับตาราง `TbHealthRecords` ตาม 6620310001_HealthMateDB.sql
class TbHealthRecord {
  final int nRecordId;
  final int nUserId;
  final double nWeight;
  final double nHeight;
  final double nBmi;
  final double nTdee;
  final DateTime dtRecordedAt;

  // Extra computed metadata for UI display
  final double? computedBmr;
  final String? activityLevelTitle;

  TbHealthRecord({
    required this.nRecordId,
    required this.nUserId,
    required this.nWeight,
    required this.nHeight,
    required this.nBmi,
    required this.nTdee,
    DateTime? dtRecordedAt,
    this.computedBmr,
    this.activityLevelTitle,
  }) : dtRecordedAt = dtRecordedAt ?? DateTime.now();

  BMICategory get bmiCategoryObj => HealthCalculator.getBMICategory(nBmi);

  Map<String, dynamic> toMap() {
    return {
      'nRecordId': nRecordId,
      'nUserId': nUserId,
      'nWeight': nWeight,
      'nHeight': nHeight,
      'nBmi': nBmi,
      'nTdee': nTdee,
      'computedBmr': computedBmr,
      'activityLevelTitle': activityLevelTitle,
      'dtRecordedAt': dtRecordedAt.toIso8601String(),
    };
  }

  factory TbHealthRecord.fromMap(Map<String, dynamic> map) {
    return TbHealthRecord(
      nRecordId: (map['nRecordId'] as num?)?.toInt() ?? 0,
      nUserId: (map['nUserId'] as num?)?.toInt() ?? 1,
      nWeight: (map['nWeight'] as num?)?.toDouble() ?? 0.0,
      nHeight: (map['nHeight'] as num?)?.toDouble() ?? 0.0,
      nBmi: (map['nBmi'] as num?)?.toDouble() ?? 0.0,
      nTdee: (map['nTdee'] as num?)?.toDouble() ?? 0.0,
      dtRecordedAt: DateTime.tryParse(map['dtRecordedAt']?.toString() ?? '') ?? DateTime.now(),
      computedBmr: (map['computedBmr'] as num?)?.toDouble(),
      activityLevelTitle: map['activityLevelTitle']?.toString(),
    );
  }
}

