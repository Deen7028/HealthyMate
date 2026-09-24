import 'dart:io';
import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class DataExportService {
  DataExportService._();
  static final DataExportService instance = DataExportService._();

  /// ส่งออกประวัติการออกกำลังกายและน้ำหนักเป็นไฟล์ CSV
  Future<String?> exportDataToCsv(int userId) async {
    try {
      final workouts = await AppDatabase.instance.getWorkouts(userId: userId);
      final healthRecords = await AppDatabase.instance.getHealthRecords(userId: userId);

      final StringBuffer csvContent = StringBuffer();
      // Section 1: Workouts
      csvContent.writeln('--- WORKOUT HISTORY ---');
      csvContent.writeln('Workout ID,Type,Distance (km),Duration (sec),Calories (kcal),Date');
      for (final w in workouts) {
        csvContent.writeln(
          '${w['nWorkoutId']},"${w['sType']}",${w['nDistance']},${w['nDuration']},${w['nCaloriesBurned']},"${w['dtWorkoutDate']}"',
        );
      }

      csvContent.writeln();

      // Section 2: Weight & Health Records
      csvContent.writeln('--- WEIGHT & HEALTH HISTORY ---');
      csvContent.writeln('Record ID,Weight (kg),Height (cm),BMI,TDEE,Recorded Date');
      for (final r in healthRecords) {
        csvContent.writeln(
          '${r.nRecordId},${r.nWeight},${r.nHeight},${r.nBmi},${r.nTdee},"${r.dtRecordedAt.toIso8601String()}"',
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/healthymate_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvContent.toString());

      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)], text: 'ประวัติสุขภาพและการออกกำลังกาย HealthyMate (CSV)');
      return file.path;
    } catch (e) {
      debugPrint('Error exporting CSV: $e');
      return null;
    }
  }

  /// ส่งออกประวัติการออกกำลังกายและน้ำหนักเป็นไฟล์ PDF
  Future<String?> exportDataToPdf(int userId) async {
    try {
      final workouts = await AppDatabase.instance.getWorkouts(userId: userId);
      final healthRecords = await AppDatabase.instance.getHealthRecords(userId: userId);

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text('HealthyMate - Health & Workout Summary Report', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 12),
              pw.Text('Exported Date: ${DateTime.now().toIso8601String().substring(0, 10)}', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 16),
              pw.Text('1. Workout History', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Type', 'Distance (km)', 'Duration (min)', 'Calories (kcal)', 'Date'],
                data: workouts.map((w) {
                  final durMin = ((w['nDuration'] as num?)?.toInt() ?? 0) ~/ 60;
                  return [
                    w['sType']?.toString() ?? '',
                    w['nDistance']?.toString() ?? '0',
                    '$durMin m',
                    w['nCaloriesBurned']?.toString() ?? '0',
                    (w['dtWorkoutDate']?.toString() ?? '').substring(0, 10),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text('2. Weight & Health Records', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: ['Weight (kg)', 'Height (cm)', 'BMI', 'TDEE', 'Date'],
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
}
