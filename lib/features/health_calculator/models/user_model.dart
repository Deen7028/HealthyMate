import 'package:healthymate/core/utils/health_calculator.dart';
import 'package:healthymate/features/health_calculator/models/activity_level.dart';

/// Data Model สำหรับตาราง `TbUsers` ตาม 6620310001_HealthMateDB.sql
class TbUser {
  final int nUserId;
  final String sEmail;
  final String sPasswordHash;
  final String sFirstName;
  final String sLastName;
  final int? nAge;
  final double? nHeight;
  final double? nWeight;
  final String? sGender; // 'male' / 'female' / null
  final String? sActivityLevel; // 'sedentary', 'light', 'moderate', 'heavy', 'very_heavy' / null
  final bool isDarkMode;
  final DateTime dtCreatedAt;

  TbUser({
    required this.nUserId,
    required this.sEmail,
    required this.sPasswordHash,
    required this.sFirstName,
    required this.sLastName,
    this.nAge,
    this.nHeight,
    this.nWeight,
    this.sGender,
    this.sActivityLevel,
    this.isDarkMode = false,
    DateTime? dtCreatedAt,
  }) : dtCreatedAt = dtCreatedAt ?? DateTime.now();

  String get sFullName => '$sFirstName $sLastName'.trim();

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
      'sFirstName': sFirstName,
      'sLastName': sLastName,
      'nAge': nAge,
      'nHeight': nHeight,
      'nWeight': nWeight,
      'sGender': sGender,
      'sActivityLevel': sActivityLevel,
      'isDarkMode': isDarkMode ? 1 : 0,
      'dtCreatedAt': dtCreatedAt.toIso8601String(),
    };
  }

  static double? _toDoubleNullable(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString());
  }

  static int? _toIntNullable(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString());
  }

  static int _toInt(dynamic val, [int defaultVal = 0]) {
    if (val == null) return defaultVal;
    if (val is num) return val.toInt();
    return int.tryParse(val.toString()) ?? defaultVal;
  }

  factory TbUser.fromMap(Map<String, dynamic> map) {
    String firstName = map['sFirstName']?.toString() ?? '';
    String lastName = map['sLastName']?.toString() ?? '';
    if (firstName.isEmpty && lastName.isEmpty && map['sFullName'] != null) {
      final parts = map['sFullName'].toString().split(' ');
      firstName = parts.isNotEmpty ? parts.first : 'ผู้ใช้งาน';
      lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    final isDarkVal = map['isDarkMode'];
    final bool isDark = isDarkVal is bool
        ? isDarkVal
        : (_toInt(isDarkVal) == 1);

    return TbUser(
      nUserId: _toInt(map['nUserId'], 1),
      sEmail: map['sEmail']?.toString() ?? 'user@healthymate.app',
      sPasswordHash: map['sPasswordHash']?.toString() ?? '',
      sFirstName: firstName.isNotEmpty ? firstName : 'ผู้ใช้งาน',
      sLastName: lastName,
      nAge: _toIntNullable(map['nAge']),
      nHeight: _toDoubleNullable(map['nHeight']),
      nWeight: _toDoubleNullable(map['nWeight']),
      sGender: map['sGender']?.toString(),
      sActivityLevel: map['sActivityLevel']?.toString(),
      isDarkMode: isDark,
      dtCreatedAt: DateTime.tryParse(map['dtCreatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
