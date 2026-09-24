import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class WorkoutShareScreen extends StatefulWidget {
  final String sType;
  final double nDistance;
  final int nDuration;
  final double nCalories;
  final List<LatLng> routePoints;

  const WorkoutShareScreen({
    super.key,
    required this.sType,
    required this.nDistance,
    required this.nDuration,
    required this.nCalories,
    this.routePoints = const [],
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
    final textShadows = _isTransparent
        ? const [
            Shadow(
              color: Colors.black87,
              blurRadius: 6,
              offset: Offset(0, 1),
            ),
          ]
        : null;

    return Container(
      width: 280,
      height: 480,
      decoration: BoxDecoration(
        color: _isTransparent ? Colors.transparent : const Color(0xFF233620),
        borderRadius: BorderRadius.circular(24),
        border: _isTransparent
            ? null
            : Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              'ระยะทาง',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                shadows: textShadows,
              ),
            ),
            Text(
              '${widget.nDistance.toStringAsFixed(2)} กม.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                shadows: textShadows,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'เพซ',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                shadows: textShadows,
              ),
            ),
            Text(
              '${_calculatePace()} /กม.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                shadows: textShadows,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'เวลา',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                shadows: textShadows,
              ),
            ),
            Text(
              _formatDuration(widget.nDuration),
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                shadows: textShadows,
              ),
            ),
            const SizedBox(height: 24),
            // วาดเส้นทาง GPS จริงที่ผู้ใช้วิ่ง/ออกกำลังกาย
            if (widget.routePoints.length >= 2)
              CustomPaint(
                size: const Size(140, 90),
                painter: _MiniRoutePainter(points: widget.routePoints),
              )
            else
              const SizedBox(height: 90),
            const SizedBox(height: 30),
            Text(
              'HEALTHYMATE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                shadows: textShadows,
              ),
            ),
          ],
        ),
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
  final List<LatLng> points;

  _MiniRoutePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = const Color(0xFFFC5200) // ส้มสไตล์ Strava
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // หา bounding box ของพิกัด
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final double latSpan = maxLat - minLat;
    final double lngSpan = maxLng - minLng;

    const double padding = 10.0;
    final double drawWidth = size.width - (padding * 2);
    final double drawHeight = size.height - (padding * 2);

    // คำนวณ scale ให้รักษาสัดส่วน Aspect Ratio (lat/lng)
    final double scaleX = lngSpan == 0 ? 1.0 : drawWidth / lngSpan;
    final double scaleY = latSpan == 0 ? 1.0 : drawHeight / latSpan;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    // หา offset กึ่งกลาง
    final double actualWidth = lngSpan * scale;
    final double actualHeight = latSpan * scale;
    final double offsetX = padding + (drawWidth - actualWidth) / 2;
    final double offsetY = padding + (drawHeight - actualHeight) / 2;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      // Note: ละติจูด ค่ามากอยู่ด้านบน (North) ดังนั้น canvas Y ต้องกลับด้าน
      final double x = offsetX + (lngSpan == 0 ? drawWidth / 2 : (p.longitude - minLng) * scale);
      final double y = offsetY + (latSpan == 0 ? drawHeight / 2 : (maxLat - p.latitude) * scale);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniRoutePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}