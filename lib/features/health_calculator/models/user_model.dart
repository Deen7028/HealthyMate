import 'package:healthymate/core/utils/health_calculator.dart';
import 'package:healthymate/features/health_calculator/models/activity_level.dart';

/// Data Model สำหรับตาราง `TbUsers` ตาม 6620310001_HealthMateDB.sql
class TbUser {
  final int nUserId;
  final String sEmail;
  final String sPasswordHash;
  final String sFirstName;
  final String sLastName;
  final int nAge;
  final double nHeight;
  final double nWeight;
  final String sGender; // 'male' / 'female'
  final String sActivityLevel; // 'sedentary', 'light', 'moderate', 'heavy', 'very_heavy'
  final bool isDarkMode;
  final String sProfileImagePath; // เก็บ path รูปโปรไฟล์ (ถ้าไม่มีจะเป็นค่าว่าง)
  final DateTime dtCreatedAt;

  TbUser({
    required this.nUserId,
    required this.sEmail,
    required this.sPasswordHash,
    required this.sFirstName,
    required this.sLastName,
    required this.nAge,
    required this.nHeight,
    required this.nWeight,
    required this.sGender,
    required this.sActivityLevel,
    this.isDarkMode = false,
    this.sProfileImagePath = '',
    DateTime? dtCreatedAt,
  }) : dtCreatedAt = dtCreatedAt ?? DateTime.now();

  String get sFullName => '$sFirstName $sLastName'.trim();

  Gender get genderEnum => sGender == 'female' ? Gender.female : Gender.male;

  TbUser copyWith({
    int? nUserId,
    String? sEmail,
    String? sPasswordHash,
    String? sFirstName,
    String? sLastName,
    int? nAge,
    double? nHeight,
    double? nWeight,
    String? sGender,
    String? sActivityLevel,
    bool? isDarkMode,
    String? sProfileImagePath,
    DateTime? dtCreatedAt,
  }) {
    return TbUser(
      nUserId: nUserId ?? this.nUserId,
      sEmail: sEmail ?? this.sEmail,
      sPasswordHash: sPasswordHash ?? this.sPasswordHash,
      sFirstName: sFirstName ?? this.sFirstName,
      sLastName: sLastName ?? this.sLastName,
      nAge: nAge ?? this.nAge,
      nHeight: nHeight ?? this.nHeight,
      nWeight: nWeight ?? this.nWeight,
      sGender: sGender ?? this.sGender,
      sActivityLevel: sActivityLevel ?? this.sActivityLevel,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      sProfileImagePath: sProfileImagePath ?? this.sProfileImagePath,
      dtCreatedAt: dtCreatedAt ?? this.dtCreatedAt,
    );
  }

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
      'sProfileImagePath': sProfileImagePath,
      'dtCreatedAt': dtCreatedAt.toIso8601String(),
    };
  }

  /// สำหรับส่งข้อมูล Profile ไปยัง API ภายนอก โดยไม่แนบ Password Hash หรือข้อมูลความปลอดภัยลับ
  Map<String, dynamic> toPublicProfileMap() {
    return {
      'nUserId': nUserId,
      'sEmail': sEmail,
      'sFirstName': sFirstName,
      'sLastName': sLastName,
      'nAge': nAge,
      'nHeight': nHeight,
      'nWeight': nWeight,
      'sGender': sGender,
      'sActivityLevel': sActivityLevel,
      'isDarkMode': isDarkMode ? 1 : 0,
      'sProfileImagePath': sProfileImagePath,
      'dtCreatedAt': dtCreatedAt.toIso8601String(),
    };
  }

  factory TbUser.fromMap(Map<String, dynamic> map) {
    String firstName = map['sFirstName']?.toString() ?? '';
    String lastName = map['sLastName']?.toString() ?? '';
    if (firstName.isEmpty && lastName.isEmpty && map['sFullName'] != null) {
      final parts = map['sFullName'].toString().split(' ');
      firstName = parts.isNotEmpty ? parts.first : 'ผู้ใช้งาน';
      lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    return TbUser(
      nUserId: (map['nUserId'] as num?)?.toInt() ?? 1,
      sEmail: map['sEmail'] ?? 'user@healthymate.app',
      sPasswordHash: map['sPasswordHash'] ?? '',
      sFirstName: firstName.isNotEmpty ? firstName : 'ผู้ใช้งาน',
      sLastName: lastName,
      nAge: (map['nAge'] as num?)?.toInt() ?? 0,
      nHeight: (map['nHeight'] as num?)?.toDouble() ?? 0.0,
      nWeight: (map['nWeight'] as num?)?.toDouble() ?? 0.0,
      sGender: map['sGender'] ?? 'male',
      sActivityLevel: map['sActivityLevel'] ?? 'light',
      isDarkMode: (map['isDarkMode'] as num?)?.toInt() == 1,
      sProfileImagePath: map['sProfileImagePath']?.toString() ?? '',
      dtCreatedAt: DateTime.tryParse(map['dtCreatedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
