part of 'step_tracker_service.dart';

// ส่วนอ่านก้าวสดจากเซ็นเซอร์ Step Counter และ Step Detector ของเครื่อง (Real-time Pedometer Sensor)
// เซ็นเซอร์คืนค่าก้าวสะสมตั้งแต่เปิดเครื่อง จึงต้องเก็บ Baseline รายวันไว้ลบออก
extension StepTrackerSensor on StepTrackerService {
  static const String _kBaseDate = 'pedo_base_date';
  static const String _kBaseCount = 'pedo_base_count';
  static const String _kLastRaw = 'pedo_last_raw';
  static const String _kLastToday = 'pedo_last_today';
  static const EventChannel _stepDetectChannel = EventChannel('step_detection');

  String _sTodayKey() {
    final DateTime dtNow = DateTime.now();
    return '${dtNow.year}-${dtNow.month.toString().padLeft(2, '0')}-${dtNow.day.toString().padLeft(2, '0')}';
  }

  // เริ่มฟังสตรีมก้าวจากเซ็นเซอร์ (รองรับทั้ง Hardware Step Counter และ Live Step Detector)
  Future<void> startSensorStream() async {
    try {
      final PermissionStatus objStatus =
          await Permission.activityRecognition.request();
      if (!objStatus.isGranted) return;

      // 1. ฟังสตรีมฮาร์ดแวร์นับก้าวโดยรวม (Step Counter)
      await _subStepCount?.cancel();
      _subStepCount = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: (Object objErr) {
          debugPrint('Pedometer stepCount error: $objErr');
        },
        cancelOnError: false,
      );

      // 2. ฟังสตรีมตรวจจับการก้าวแบบ Real-Time ทันที (Step Detector) เพื่อให้หน้าจอขยับทันทีทุกก้าว
      await _subStepDetect?.cancel();
      _subStepDetect = _stepDetectChannel.receiveBroadcastStream().listen(
        _onStepDetected,
        onError: (Object objErr) {
          debugPrint('Pedometer stepDetect not supported or error: $objErr');
        },
        cancelOnError: false,
      );
    } catch (objErr) {
      debugPrint('startSensorStream error: $objErr');
    }
  }

  // ตรวจจับก้าวเดินแบบ Real-time ทันทีเมื่อเท้าเหยียบลงพื้น (< 0.5 วินาที)
  void _onStepDetected(Object? objEvent) {
    if (!_isTrackingEnabled) return;
    final DateTime dtNow = DateTime.now();
    if (_dtLastStepTime != null &&
        dtNow.difference(_dtLastStepTime!).inMilliseconds < 60) {
      return;
    }
    _dtLastStepTime = dtNow;

    final int nNewSteps = _nTodaySteps + 1;
    _nSensorSteps = nNewSteps;
    _applyStepValues(nNewSteps);
  }

  // ซิงค์ยอดก้าวที่แม่นยำจากฮาร์ดแวร์นับก้าวของเครื่อง (TYPE_STEP_COUNTER)
  Future<void> _onStepCount(StepCount objEvent) async {
    final int nRaw = objEvent.steps;
    final SharedPreferences objPrefs = await SharedPreferences.getInstance();
    final String sToday = _sTodayKey();
    final String sBaseDate = objPrefs.getString(_kBaseDate) ?? '';
    int? nBase = objPrefs.getInt(_kBaseCount);
    final int nLastRaw = objPrefs.getInt(_kLastRaw) ?? nRaw;

    if (sBaseDate != sToday) {
      // วันใหม่เสมอ → รีเซ็ตเริ่มนับจากศูนย์อย่างเคร่งครัดตามข้อกำหนดของผู้ใช้
      nBase = nRaw;
      await objPrefs.setString(_kBaseDate, sToday);
      await objPrefs.setInt(_kBaseCount, nBase);
      await objPrefs.setInt(_kLastRaw, nRaw);
      await objPrefs.setInt(_kLastToday, 0);
      _nHealthSteps = 0;
      _nSensorSteps = 0;
      _applyStepValues(0, isForce: true);
      return;
    }

    // หากเครื่องรีบูต (nRaw น้อยกว่าค่าเดิม)
    if (nRaw < nLastRaw) {
      nBase = nRaw - _nTodaySteps;
      await objPrefs.setInt(_kBaseCount, nBase);
    } else if (nBase == null) {
      // เริ่มต้นวันแรก
      nBase = nRaw - _nTodaySteps;
      await objPrefs.setInt(_kBaseCount, nBase);
    } else if (nRaw - nBase < _nTodaySteps && _nTodaySteps > 0) {
      // เชื่อมต่อทันที: ป้องกัน Deadband ไม่ให้ค่าค้าง
      nBase = nRaw - _nTodaySteps;
      await objPrefs.setInt(_kBaseCount, nBase);
    }

    final int nSensorToday = (nRaw - nBase).clamp(0, 200000);
    await objPrefs.setInt(_kLastRaw, nRaw);
    await objPrefs.setInt(_kLastToday, nSensorToday);

    _nSensorSteps = nSensorToday;
    if (nSensorToday > _nTodaySteps) {
      _applyStepValues(nSensorToday);
    }
  }
}
