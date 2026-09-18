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

  static double _toDouble(dynamic val, [double defaultVal = 0.0]) {
    if (val == null) return defaultVal;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? defaultVal;
  }

  static int _toInt(dynamic val, [int defaultVal = 0]) {
    if (val == null) return defaultVal;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? defaultVal;
  }

  factory TbHealthRecord.fromMap(Map<String, dynamic> map) {
    return TbHealthRecord(
      nRecordId: _toInt(map['nRecordId']),
      nUserId: _toInt(map['nUserId'], 1),
      nWeight: _toDouble(map['nWeight']),
      nHeight: _toDouble(map['nHeight']),
      nBmi: _toDouble(map['nBmi']),
      nTdee: _toDouble(map['nTdee']),
      dtRecordedAt: DateTime.tryParse(map['dtRecordedAt']?.toString() ?? '') ?? DateTime.now(),
      computedBmr: map['computedBmr'] != null ? _toDouble(map['computedBmr']) : null,
      activityLevelTitle: map['activityLevelTitle']?.toString(),
    );
  }
}

