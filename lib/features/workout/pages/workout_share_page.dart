import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/index.dart';

/// หน้าจอแชร์สรุปผลการออกกำลังกาย (Workout Share & Export Page)
/// แสดงการ์ดสรุปสถิติและเส้นทาง GPS พร้อมฟังก์ชันเซฟเป็นภาพลง Gallery และแชร์ไปยังโซเชียลมีเดีย
class WorkoutSharePage extends StatefulWidget {
  /// ชื่อประเภทกิจกรรมออกกำลังกาย (เช่น วิ่ง, เดิน, ปั่นจักรยาน)
  final String sType;

  /// ระยะทางสะสม (กิโลเมตร)
  final double nDistance;

  /// ระยะเวลาทั้งหมด (วินาที)
  final int nDuration;

  /// จำนวนแคลอรีที่เผาผลาญ (kcal)
  final double nCalories;

  /// รายการจุดพิกัดเส้นทางทั้งหมดสำหรับการวาดมินิแมป
  final List<LatLng> routePoints;

  const WorkoutSharePage({
    super.key,
    required this.sType,
    required this.nDistance,
    required this.nDuration,
    required this.nCalories,
    this.routePoints = const [],
  });

  @override
  State<WorkoutSharePage> createState() => _WorkoutSharePageState();
}

class _WorkoutSharePageState extends State<WorkoutSharePage> {
  /// GlobalKey สำหรับอ้างอิง RepaintBoundary เพื่อ Render เป็นไฟล์รูปภาพ PNG
  final GlobalKey _globalKey = GlobalKey();

  /// สถานะสลับการ์ดโหมดโปร่งใส (Glassmorphic) หรือโหมดทึบแสง
  bool _isTransparent = true;

  /// สถานะกำลังประมวลผลเซฟรูปหรือแชร์
  bool _isProcessing = false;

  /// ชนิด Action ที่กำลังประมวลผลอยู่ ('save' หรือ 'share')
  String _processAction = '';

  /// แปลง RepaintBoundary บน UI เป็นไฟล์รูปภาพ PNG ความละเอียดสูง (3.0 pixel ratio)
  Future<File?> _generateImageFile() async {
    final boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/healthymate_workout_${DateTime.now().millisecondsSinceEpoch}.png').create();
    await file.writeAsBytes(pngBytes);
    return file;
  }

  // บันทึกลงอัลบั้มรูปภาพในเครื่อง (Gallery)
  Future<void> _saveToGallery() async {
    setState(() {
      _isProcessing = true;
      _processAction = 'save';
    });

    try {
      final file = await _generateImageFile();
      if (file == null) return;

      // ขอสิทธิ์และบันทึกเข้า Photos/Gallery
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final request = await Gal.requestAccess();
        if (!request) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('กรุณาอนุญาตสิทธิ์การเข้าถึงคลังรูปภาพเพื่อบันทึก'),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      }

      await Gal.putImage(file.path);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('บันทึกรูปลงคลังภาพในเครื่องเรียบร้อยแล้ว! 📸')),
              ],
            ),
            backgroundColor: const Color(0xFF2E5327),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Save to gallery error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึกรูป: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processAction = '';
        });
      }
    }
  }

  // แปลง RepaintBoundary เป็นไฟล์รูปภาพ PNG แล้วแชร์
  Future<void> _exportAndShare() async {
    setState(() {
      _isProcessing = true;
      _processAction = 'share';
    });

    try {
      final file = await _generateImageFile();
      if (file == null) return;

      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'การออกกำลังกายวันนี้กับ HealthyMate 🍏',
      );
    } catch (e) {
      debugPrint('Share error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processAction = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181C17),
      appBar: AppBar(
        title: const Text('แชร์กิจกรรม', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: RepaintBoundary(
                  key: _globalKey,
                  child: _buildShareCard(),
                ),
              ),
            ),
          ),
          _buildShareActions(),
        ],
      ),
    );
  }

  Widget _buildShareCard() {
    return WorkoutShareCard(
      distance: widget.nDistance,
      duration: widget.nDuration,
      routePoints: widget.routePoints,
      isTransparent: _isTransparent,
    );
  }

  Widget _buildShareActions() {
    return WorkoutShareActions(
      isTransparent: _isTransparent,
      isProcessing: _isProcessing,
      processAction: _processAction,
      onToggleTransparent: () => setState(() => _isTransparent = !_isTransparent),
      onSaveToGallery: _saveToGallery,
      onExportAndShare: _exportAndShare,
    );
  }
}