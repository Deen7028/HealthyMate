import 'package:healthymate/core/utils/health_calculator.dart';
import 'package:healthymate/features/health_calculator/models/activity_level.dart';

/// Data Model สำหรับตาราง `TbUsers` ตาม 6620310001_HealthMateDB.sql
class TbUser {
  final int nUserId;
  final String sEmail;
  final String sPasswordHash;
  final String sFullName;
  final int nAge;
  final double nHeight;
  final double nWeight;
  final String sGender; // 'male' / 'female'
  final String sActivityLevel; // 'sedentary', 'light', 'moderate', 'heavy', 'very_heavy'
  final bool isDarkMode;
  final DateTime dtCreatedAt;

  TbUser({
    required this.nUserId,
    required this.sEmail,
    required this.sPasswordHash,
    required this.sFullName,
    required this.nAge,
    required this.nHeight,
    required this.nWeight,
    required this.sGender,
    required this.sActivityLevel,
    this.isDarkMode = false,
    DateTime? dtCreatedAt,
  }) : dtCreatedAt = dtCreatedAt ?? DateTime.now();

  Gender get genderEnum => sGender == 'female' ? Gender.female : Gender.male;

  ActivityLevel get activityLevelObj => ActivityLevel.options.firstWhere(
        (opt) => opt.id == sActivityLevel,
        orElse: () => ActivityLevel.options[1],
      );

  Map<String, dynamic> toMap() {
    return {
      'nUserId': nUserId,
      'sEmail': sEmail,
      'sPasswordHash': sPasswordHash,
      'sFullName': sFullName,
      'nAge': nAge,
      'nHeight': nHeight,
      'nWeight': nWeight,
      'sGender': sGender,
      'sActivityLevel': sActivityLevel,
      'isDarkMode': isDarkMode ? 1 : 0,
      'dtCreatedAt': dtCreatedAt.toIso8601String(),
    };
  }

  factory TbUser.fromMap(Map<String, dynamic> map) {
    return TbUser(
      nUserId: (map['nUserId'] as num?)?.toInt() ?? 1,
      sEmail: map['sEmail'] ?? 'user@healthymate.app',
      sPasswordHash: map['sPasswordHash'] ?? '',
      sFullName: map['sFullName'] ?? 'ผู้ใช้งาน',
      nAge: (map['nAge'] as num?)?.toInt() ?? 28,
      nHeight: (map['nHeight'] as num?)?.toDouble() ?? 175.0,
      nWeight: (map['nWeight'] as num?)?.toDouble() ?? 70.0,
      sGender: map['sGender'] ?? 'male',
      sActivityLevel: map['sActivityLevel'] ?? 'light',
      isDarkMode: (map['isDarkMode'] as num?)?.toInt() == 1,
      dtCreatedAt: DateTime.tryParse(map['dtCreatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

