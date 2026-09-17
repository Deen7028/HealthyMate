import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class WorkoutShareScreen extends StatefulWidget {
  final String sType;
  final double nDistance;
  final int nDuration;
  final double nCalories;

  const WorkoutShareScreen({
    super.key,
    required this.sType,
    required this.nDistance,
    required this.nDuration,
    required this.nCalories,
  });

  @override
  State<WorkoutShareScreen> createState() => _WorkoutShareScreenState();
}

class _WorkoutShareScreenState extends State<WorkoutShareScreen> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isTransparent = true;
  bool _isProcessing = false;
  String _processAction = '';

  // คำนวณค่าเพซ (นาที:วินาที / กม.)
  String _calculatePace() {
    if (widget.nDistance <= 0.05 || widget.nDuration <= 0) return "-:--";
    final double totalMinutes = widget.nDuration / 60.0;
    final double paceDecimal = totalMinutes / widget.nDistance;
    final int paceMin = paceDecimal.toInt();
    final int paceSec = ((paceDecimal - paceMin) * 60).round();
    return '$paceMin:${paceSec.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minsน. $secsวิ';
  }

  // แปลง RepaintBoundary เป็นไฟล์รูปภาพ PNG
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

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'การออกกำลังกายวันนี้กับ HealthyMate 🍏',
        ),
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
    return Container(
      width: 280,
      height: 480,
      decoration: BoxDecoration(
        color: _isTransparent ? Colors.black.withValues(alpha: 0.55) : const Color(0xFF233620),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Stack(
        children: [
          // ป้ายสลับโหมดโปร่งใส
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white30),
              ),
              child: Text(
                _isTransparent ? 'โปร่งใส' : 'คลาสสิก',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text('ระยะทาง', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(
                  '${widget.nDistance.toStringAsFixed(2)} กม.',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 14),
                const Text('เพซ', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(
                  '${_calculatePace()} /กม.',
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                const Text('เวลา', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(
                  _formatDuration(widget.nDuration),
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 24),
                // วาดเส้นทาง GPS แบบมินิมอล
                CustomPaint(
                  size: const Size(120, 80),
                  painter: _MiniRoutePainter(),
                ),
                const SizedBox(height: 30),
                const Text(
                  'HEALTHYMATE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('แชร์ไปยัง', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              TextButton.icon(
                icon: const Icon(Icons.style_rounded, size: 16, color: Color(0xFF2E5327)),
                label: Text(_isTransparent ? 'เปลี่ยนเป็นสีพื้น' : 'เปลี่ยนเป็นโปร่งใส',
                    style: const TextStyle(color: Color(0xFF2E5327), fontWeight: FontWeight.w600)),
                onPressed: () => setState(() => _isTransparent = !_isTransparent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ปุ่มบันทึกลงอัลบั้มรูปในเครื่อง
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: (_isProcessing && _processAction == 'save')
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.download_rounded, size: 22),
              label: Text(
                (_isProcessing && _processAction == 'save') ? 'กำลังบันทึกรูปลงเครื่อง...' : 'บันทึกรูปลงเครื่อง (Gallery)',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E5327),
                foregroundColor: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isProcessing ? null : _saveToGallery,
            ),
          ),
          const SizedBox(height: 10),
          // ปุ่มแชร์ Story / ไปยังแอปอื่นๆ
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: (_isProcessing && _processAction == 'share')
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF2E5327), strokeWidth: 2))
                  : const Icon(Icons.share_rounded, size: 20, color: Color(0xFF2E5327)),
              label: Text(
                (_isProcessing && _processAction == 'share') ? 'กำลังเตรียมแชร์...' : 'แชร์ไปยัง Story หรือแอปอื่นๆ',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF2E5327)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2E5327), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isProcessing ? null : _exportAndShare,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFC5200) // ส้มสไตล์ Strava
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.8)
      ..lineTo(size.width * 0.45, size.height * 0.2)
      ..lineTo(size.width * 0.8, size.height * 0.3)
      ..lineTo(size.width * 0.35, size.height * 0.9)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}