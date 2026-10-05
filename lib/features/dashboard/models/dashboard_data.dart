// ส่วนนี้อธิบายบทบาทของไฟล์: โมเดลข้อมูล ในฟีเจอร์แดชบอร์ดสรุปสุขภาพและเป้าหมาย (dashboard data)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'package:flutter/material.dart';

/// โมเดลข้อมูลรายการเช็คลิสต์กิจวัตรประจำวัน (Daily Checklist Item Model)
class DailyChecklistItem {
  /// รหัสประจำตัวไอเทม
  final String id;

  /// หัวข้อกิจวัตร
  final String title;

  /// รายละเอียดหรือคำอธิบายย่อย
  final String subtitle;

  /// ไอคอนประจำกิจวัตร
  final IconData icon;

  /// สีธีมของกิจวัตร
  final Color color;

  /// สถานะการเสร็จสิ้นกิจวัตร
  bool isCompleted;

  DailyChecklistItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isCompleted = false,
  });
}

/// โมเดลข้อมูลสถิติสรุปภาพรวมสำหรับ Dashboard (Dashboard Stats Model)
class DashboardStats {
  /// ระยะทางรวม (กิโลเมตร)
  double distanceKm;

  /// เวลาที่ทำกิจกรรมรวม (นาที)
  int activeTimeMinutes;

  /// แคลอรีที่เผาผลาญรวม (กิโลแคลอรี)
  int caloriesBurned;

  /// จำนวนก้าวเดินรวม
  int stepCount;

  DashboardStats({
    this.distanceKm = 4.2,
    this.activeTimeMinutes = 45,
    this.caloriesBurned = 320,
    this.stepCount = 6840,
  });
}
