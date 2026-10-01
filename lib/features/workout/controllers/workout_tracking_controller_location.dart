part of 'workout_tracking_controller.dart';

extension WorkoutTrackingLocation on WorkoutTrackingController {
  void _handleNewLocation({
    required double latitude,
    required double longitude,
    required double speedMs,
    required double accuracy,
    DateTime? timestamp,
  }) {
    // 0. หากเป็นกิจกรรมที่ไม่เกี่ยวกับการเคลื่อนที่ (ทำสมาธิ/โยคะ) ไม่ต้องบันทึกระยะทางและเส้นทาง GPS
    if (!_selectedCategory.isMoving) {
      return;
    }

    final newTime = timestamp ?? DateTime.now();

    // 1. ตรวจสอบความเร็วสำหรับ Auto-Pause (ความเร็วน้อยกว่า 0.3 m/s หรือ 1 km/h ถือว่าหยุดนิ่ง)
    if (speedMs < 0.3) {
      _zeroSpeedSeconds++;
    } else {
      _zeroSpeedSeconds = 0;
      if (_isAutoPaused) {
        _isAutoPaused = false;
        TtsService.instance.speak('เริ่มบันทึกกิจกรรมต่ออัตโนมัติ');
      }
    }

    if (_isAutoPaused) return;

    if (_lastPosition != null) {
      // ป้องกันพิกัดที่ย้อนหลังหรือมาสลับลำดับเวลา (Chronological Check)
      final timeDifferenceSec =
          newTime.difference(_lastPosition!.timestamp).inMilliseconds / 1000.0;
      if (timeDifferenceSec <= 0.3) {
        return;
      }

      final distanceInMeters = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        latitude,
        longitude,
      );

      // คำนวณความเร็วเฉลี่ยระหว่างจุดจริง (Calculated Speed = distance / time)
      final calculatedSpeedMs = timeDifferenceSec > 0
          ? (distanceInMeters / timeDifferenceSec)
          : 0.0;

      // กรอง GPS Drift เข้มงวดระดับแอปออกกำลังกายมาตรฐาน:
      // 1. ความแม่นยำสัญญาณ GPS (accuracy) ต้องดีกว่า 15 เมตร
      // 2. ระยะทางขยับขั้นต่ำต้อง >= 5.0 เมตร (สอดคล้องกับ distanceFilter)
      // 3. ความเร็วที่คำนวณได้จริงต้องไม่เกิน 15.0 m/s (~54 km/h) สำหรับกีฬาเดิน/วิ่ง/จักรยาน
      // 4. หากมีค่า speed จากฮาร์ดแวร์ ต้องสอดคล้อง ไม่ก้าวกระโดดผิดธรรมชาติ
      final bool isAccuracyValid = accuracy <= 15.0;
      final bool isDistanceValid =
          distanceInMeters >= 5.0 && distanceInMeters < 120.0;
      final bool isSpeedValid = calculatedSpeedMs < 15.0 && speedMs < 20.0;

      // ตรวจสอบว่าพิกัดขยับพ้นจากวงรัศมีคลาดเคลื่อน GPS (Displacement Threshold)
      final bool isClearDisplacement = distanceInMeters >= (accuracy * 0.8);

      final bool isRealMovement =
          isAccuracyValid &&
          isDistanceValid &&
          isSpeedValid &&
          isClearDisplacement;

      if (isRealMovement) {
        final addedKm = distanceInMeters / 1000.0;
        _distanceKm += addedKm;

        // หากยังไม่มีจุดในเส้นทาง ให้เพิ่มจุดเริ่มต้นก่อน
        if (_routePoints.isEmpty) {
          _routePoints.add(
            LatLng(_lastPosition!.latitude, _lastPosition!.longitude),
          );
        }

        _lastPosition = Position(
          longitude: longitude,
          latitude: latitude,
          timestamp: newTime,
          accuracy: accuracy,
          altitude: 0.0,
          altitudeAccuracy: 0.0,
          heading: 0.0,
          headingAccuracy: 0.0,
          speed: speedMs,
          speedAccuracy: 0.0,
        );

        _routePoints.add(LatLng(latitude, longitude));
        this._safeNotifyListeners();

        // 2. Voice Feedback: ทุกๆ 1 กิโลเมตร ให้ ขานบอกระยะทาง เวลา และ Pace
        final currentKmFloor = _distanceKm.floor();
        if (currentKmFloor > _lastAnnouncedKm && currentKmFloor >= 1) {
          _lastAnnouncedKm = currentKmFloor;
          final double validDistance = _distanceKm >= 0.05 ? _distanceKm : 0.0;
          final double paceMinutesPerKm = validDistance > 0
              ? ((_secondsElapsed / 60.0) / validDistance).clamp(0.0, 99.0)
              : 0.0;
          final int paceMin = paceMinutesPerKm.floor();
          final int paceSec = ((paceMinutesPerKm - paceMin) * 60).round();
          final paceStr =
              '$paceMin นาที ${paceSec.toString().padLeft(2, '0')} วินาที ต่อกิโลเมตร';
          TtsService.instance.announceWorkoutProgress(
            distanceKm: _distanceKm,
            secondsElapsed: _secondsElapsed,
            paceText: paceStr,
          );
        }
      }
    } else {
      _lastPosition = Position(
        longitude: longitude,
        latitude: latitude,
        timestamp: newTime,
        accuracy: accuracy,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: speedMs,
        speedAccuracy: 0.0,
      );
      _routePoints.add(LatLng(latitude, longitude));
      this._safeNotifyListeners();
    }
  }
}
