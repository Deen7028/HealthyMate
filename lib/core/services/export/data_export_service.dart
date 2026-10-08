import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:healthymate/core/database/app_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
// ส่งออกประวัติการออกกำลังกายและน้ำหนักเป็นไฟล์ PDF
class DataExportService {
  DataExportService._();
  static final DataExportService instance = DataExportService._();

  // ส่งออกประวัติการออกกำลังกายและน้ำหนักเป็นไฟล์ PDF (รองรับภาษาไทย 100% ด้วยฟอนต์ Sarabun)
  Future<String?> exportDataToPdf(int userId) async {
    try {
      final workouts = await AppDatabase.instance.getWorkouts(userId: userId);
      final healthRecords = await AppDatabase.instance.getHealthRecords(userId: userId);

      // โหลดฟอนต์ภาษาไทยจาก Assets เพื่อแก้ปัญหาสระลอย / ฟอนต์สี่เหลี่ยมใน PDF
      final fontDataRegular = await rootBundle.load('assets/fonts/Sarabun-Regular.ttf');
      final fontDataBold = await rootBundle.load('assets/fonts/Sarabun-Bold.ttf');
      final ttfRegular = pw.Font.ttf(fontDataRegular);
      final ttfBold = pw.Font.ttf(fontDataBold);

      final thaiTheme = pw.ThemeData.withFont(
        base: ttfRegular,
        bold: ttfBold,
      );

      final pdf = pw.Document(theme: thaiTheme);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'รายงานสรุปสุขภาพ HealthyMate',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'วันที่ส่งออกเอกสาร: ${DateTime.now().toIso8601String().substring(0, 10)}',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                '1. ประวัติการออกกำลังกาย (Workout History)',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['ประเภทกิจกรรม', 'ระยะทาง (กม.)', 'ระยะเวลา (นาที)', 'แคลอรี (kcal)', 'วันที่'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 10),
                data: workouts.map((w) {
                  final durMin = ((w['nDuration'] as num?)?.toInt() ?? 0) ~/ 60;
                  return [
                    w['sType']?.toString() ?? '',
                    w['nDistance']?.toString() ?? '0',
                    '$durMin นาที',
                    w['nCaloriesBurned']?.toString() ?? '0',
                    _dateOnly(w['dtWorkoutDate']),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                '2. ประวัติน้ำหนักและสุขภาพ (Weight & Health Records)',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['น้ำหนัก (กก.)', 'ส่วนสูง (ซม.)', 'ดรรชนีมวลกาย (BMI)', 'TDEE (kcal)', 'วันที่บันทึก'],
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: const pw.TextStyle(fontSize: 10),
                data: healthRecords.map((r) {
                  return [
                    r.nWeight.toString(),
                    r.nHeight.toString(),
                    r.nBmi.toStringAsFixed(1),
                    r.nTdee.toStringAsFixed(0),
                    r.dtRecordedAt.toIso8601String().substring(0, 10),
                  ];
                }).toList(),
              ),
            ];
          },
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/healthymate_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'รายงานสรุปประวัติสุขภาพและการออกกำลังกาย HealthyMate (PDF)');
      return file.path;
    } catch (e) {
      debugPrint('Error exporting PDF: $e');
      return null;
    }
  }

  String _dateOnly(dynamic value) {
    final raw = value?.toString() ?? '';
    if (raw.length >= 10) return raw.substring(0, 10);
    return raw.isEmpty ? 'ไม่ระบุ' : raw;
  }
}
