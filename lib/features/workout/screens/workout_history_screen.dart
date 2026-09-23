import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/sync_service.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/workout/screens/workout_share_screen.dart';

/// หน้าแสดงประวัติการออกกำลังกายจากตาราง TbWorkouts
class WorkoutHistoryScreen extends StatefulWidget {
  final int userId;

  const WorkoutHistoryScreen({super.key, required this.userId});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  bool _isLoading = true;
  bool _isPulling = false;
  List<Map<String, dynamic>> _workouts = [];

  @override
  void initState() {
    super.initState();
    _initWorkoutData();
  }

  /// ตรวจสอบเงื่อนไขการดึงข้อมูลเริ่มต้น (Initial Data Hydration Trigger)
  /// - หาก Local DB ว่างเปล่า (COUNT(*) == 0) จะสั่งดึงข้อมูลจาก Server ลงมาเติมลงเครื่องทันที
  Future<void> _initWorkoutData() async {
    await _loadWorkoutHistory();

    // ตรวจสอบว่า Local DB ว่างเปล่าหรือไม่
    try {
      final count = await AppDatabase.instance.getWorkoutCount(userId: widget.userId);
      if (count == 0 && mounted) {
        debugPrint('WorkoutHistory: Local DB is empty (COUNT == 0). Triggering Initial Pull Sync...');
        await _pullDownstreamData(isInitial: true);
      }
    } catch (e) {
      debugPrint('WorkoutHistory: Error checking workout count: $e');
    }
  }

  /// ฟังก์ชันดึงข้อมูลจากเซิร์ฟเวอร์ลงมา (Pull Downstream Sync)
  Future<void> _pullDownstreamData({bool isInitial = false}) async {
    if (!mounted) return;
    setState(() {
      _isPulling = true;
    });

    try {
      final pulledCount = await SyncService.instance.pullDownstreamWorkouts(
        widget.userId,
        forceInitial: isInitial,
      );

      // โหลดข้อมูลล่าสุดจาก SQLite หลัง Upsert เสร็จ
      final list = await AppDatabase.instance.getWorkouts(userId: widget.userId);
      if (mounted) {
        setState(() {
          _workouts = list;
          _isLoading = false;
          _isPulling = false;
        });

        if (pulledCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cloud_download_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('ดึงข้อมูลสำเร็จ $pulledCount รายการ'),
                ],
              ),
              backgroundColor: AppTheme.primaryGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('WorkoutHistory: Pull downstream error: $e');
      if (mounted) {
        setState(() {
          _isPulling = false;
        });
      }
    }
  }

  Future<void> _loadWorkoutHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final list = await AppDatabase.instance.getWorkouts(
        userId: widget.userId,
      );
      if (mounted) {
        setState(() {
          _workouts = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDuration(int seconds) {
    final hrs = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hrs > 0) {
      return '$hrs ชม. $mins นาที';
    }
    if (mins > 0) {
      return '$mins นาที $secs วิ';
    }
    return '$secs วินาที';
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year + 543; // พ.ศ.
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$min น.';
    } catch (_) {
      return dateStr;
    }
  }

  IconData _getCategoryIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('เดิน') || t.contains('walk')) {
      return Icons.directions_walk_rounded;
    } else if (t.contains('จักรยาน') ||
        t.contains('cycl') ||
        t.contains('bike')) {
      return Icons.directions_bike_rounded;
    }
    return Icons.directions_run_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F3),
      appBar: AppBar(
        title: const Text(
          'ประวัติการออกกำลังกาย',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF1C2819),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1C2819),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isPulling)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2E5327),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync_rounded, color: Color(0xFF2E5327)),
              onPressed: () => _pullDownstreamData(isInitial: false),
              tooltip: 'ดึงข้อมูลล่าสุดจากเซิร์ฟเวอร์ (Delta Sync)',
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryGreen,
        backgroundColor: Colors.white,
        onRefresh: () => _pullDownstreamData(isInitial: false),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              )
            : _workouts.isEmpty
            ? _buildEmptyState()
            : _buildHistoryList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F1E7),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD4E6D2), width: 2),
                    ),
                    child: const Icon(
                      Icons.fitness_center_rounded,
                      size: 48,
                      color: Color(0xFF2E5327),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ยังไม่มีประวัติการออกกำลังกาย',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1C2819),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'เลื่อนลงเพื่อดึงข้อมูลจาก Cloud หรือเริ่มบันทึกกิจกรรมวิ่ง เดิน หรือปั่นจักรยานใหม่',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF677366),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => _pullDownstreamData(isInitial: true),
                    icon: const Icon(Icons.cloud_download_outlined, size: 18),
                    label: const Text('ดึงข้อมูลทั้งหมดจาก Server'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: const BorderSide(color: AppTheme.primaryGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(18),
      itemCount: _workouts.length,
      itemBuilder: (context, index) {
        final item = _workouts[index];
        final type = item['sType']?.toString() ?? 'กิจกรรม';
        final distance = (item['nDistance'] as num?)?.toDouble() ?? 0.0;
        final duration = (item['nDuration'] as num?)?.toInt() ?? 0;
        final calories = (item['nCaloriesBurned'] as num?)?.toDouble() ?? 0.0;
        final dateStr = item['dtWorkoutDate']?.toString();
        final rawRoutePoints = item['sRoutePoints']?.toString();
        List<LatLng> routePoints = [];
        if (rawRoutePoints != null && rawRoutePoints.isNotEmpty) {
          try {
            final decoded = jsonDecode(rawRoutePoints) as List<dynamic>;
            routePoints = decoded
                .map((pt) => LatLng(
                      (pt['lat'] as num).toDouble(),
                      (pt['lng'] as num).toDouble(),
                    ))
                .toList();
          } catch (_) {}
        }


        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: const Color(0xFFE5ECE3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // หัวการ์ด: ไอคอน + ชื่อกิจกรรม + วันเวลา
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3EB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getCategoryIcon(type),
                      color: const Color(0xFF2E5327),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C2819),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateTime(dateStr),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7A8679),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F6F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Color(0xFF2E5327),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(duration),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E5327),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // แสดงแผนที่เฉพาะเมื่อมีพิกัดเส้นทาง GPS บันทึกไว้จริง
              // หากไม่มีเส้นทาง ให้ซ่อนแผนที่ออก เพื่อความสะอาดตา ไม่กระโดดไปพิกัดกรุงเทพฯ (Bangkok Fallback) และประหยัดทรัพยากร GPU
              if (routePoints.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: routePoints.first,
                            zoom: 16.0,
                          ),
                          liteModeEnabled: true,
                          zoomGesturesEnabled: false,
                          zoomControlsEnabled: false,
                          scrollGesturesEnabled: false,
                          rotateGesturesEnabled: false,
                          tiltGesturesEnabled: false,
                          myLocationButtonEnabled: false,
                          mapToolbarEnabled: false,
                          compassEnabled: false,
                          mapType: MapType.normal,
                          onMapCreated: (GoogleMapController controller) {
                            if (routePoints.length >= 2) {
                              double minLat = routePoints.first.latitude;
                              double maxLat = routePoints.first.latitude;
                              double minLng = routePoints.first.longitude;
                              double maxLng = routePoints.first.longitude;

                              for (final pt in routePoints) {
                                if (pt.latitude < minLat) minLat = pt.latitude;
                                if (pt.latitude > maxLat) maxLat = pt.latitude;
                                if (pt.longitude < minLng) minLng = pt.longitude;
                                if (pt.longitude > maxLng) maxLng = pt.longitude;
                              }

                              final bounds = LatLngBounds(
                                southwest: LatLng(minLat, minLng),
                                northeast: LatLng(maxLat, maxLng),
                              );
                              controller.animateCamera(
                                CameraUpdate.newLatLngBounds(bounds, 36),
                              );
                            }
                          },
                          polylines: routePoints.length >= 2
                              ? {
                                  Polyline(
                                    polylineId: PolylineId('history_route_$index'),
                                    color: const Color(0xFFFC5200), // สีส้มสไตล์ Strava
                                    width: 4,
                                    points: routePoints,
                                  ),
                                }
                              : {},
                          markers: {
                            Marker(
                              markerId: MarkerId('start_$index'),
                              position: routePoints.first,
                              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                            ),
                            if (routePoints.length >= 2)
                              Marker(
                                markerId: MarkerId('end_$index'),
                                position: routePoints.last,
                                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                              ),
                          },
                        ),
                        // ป้าย Overlay มินิระบุแผนที่เส้นทาง
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.map_rounded, color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  routePoints.length >= 2 ? 'เส้นทางจริง' : 'ตำแหน่งกิจกรรม',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF0F4EF)),
              const SizedBox(height: 14),

              // สถิติ: ระยะทาง และ แคลอรี
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.route_rounded,
                          size: 18,
                          color: Color(0xFF4A7C42),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ระยะทาง',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF7A8679),
                              ),
                            ),
                            Text(
                              '${distance.toStringAsFixed(2)} km',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1C2819),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 28,
                    width: 1,
                    color: const Color(0xFFE5ECE3),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 20,
                          color: Color(0xFFD9534F),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'เผาผลาญ',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF7A8679),
                              ),
                            ),
                            Text(
                              '${calories.toStringAsFixed(0)} kcal',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1C2819),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.share_rounded,
                        color: Color(0xFF2E5327),
                        size: 22,
                      ),
                      tooltip: 'แชร์กิจกรรม',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => WorkoutShareScreen(
                              sType: type,
                              nDistance: distance,
                              nDuration: duration,
                              nCalories: calories,
                              routePoints: routePoints,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
