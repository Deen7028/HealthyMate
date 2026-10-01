part of 'workout_tracking_page.dart';

extension WorkoutTrackingPageLocation on _WorkoutTrackingPageState {
  Future<bool> _initCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // ถ้าผู้ใช้ยังไม่ได้เปิด GPS ในเครื่อง ให้แจ้งเตือนและพาไปเปิด
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('กรุณาเปิดบริการตำแหน่ง (GPS) บนอุปกรณ์'),
              action: SnackBarAction(
                label: 'เปิด GPS',
                textColor: Colors.amberAccent,
                onPressed: () => Geolocator.openLocationSettings(),
              ),
              backgroundColor: const Color(0xFF2E5327),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        await Geolocator.openLocationSettings();
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'คุณปฏิเสธการให้สิทธิ์ตำแหน่ง GPS จึงไม่สามารถเริ่มจับเวลาออกกำลังกายได้',
                ),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'สิทธิ์ตำแหน่งถูกปิดถาวร กรุณาอนุญาตในตั้งค่าแอปก่อนเริ่มออกกำลังกาย',
              ),
              action: SnackBarAction(
                label: 'ไปที่ตั้งค่า',
                textColor: Colors.amberAccent,
                onPressed: () => Geolocator.openAppSettings(),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return false;
      }

      _state.enableGps();

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(pos.latitude, pos.longitude);
        });
        this._moveToCurrentLocation();
      }
      return true;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return false;
    }
  }

  /// เลื่อนกล้องแผนที่ไปหาตำแหน่งปัจจุบัน (ใช้พิกัดสดใหม่จาก Controller ป้องกันบั๊กปุ่มบินกลับจุดเริ่มต้น)
  Future<void> _moveToCurrentLocation() async {
    try {
      LatLng? targetPos = _state.currentLatLng;
      if (targetPos == null) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        targetPos = LatLng(pos.latitude, pos.longitude);
      }

      _state.enableGps();

      if (mounted) {
        setState(() {
          _currentPosition = targetPos;
        });
      }

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: targetPos, zoom: 16.5),
        ),
      );
    } catch (e) {
      debugPrint('Error moving to location: $e');
    }
  }
}
