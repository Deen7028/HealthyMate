part of 'workout_tracking_controller.dart';

extension WorkoutTrackingLifecycle on WorkoutTrackingController {
  Future<void> _loadUserData() async {
    try {
      final email = AuthService.instance.currentUserEmail;
      final user = email.isNotEmpty
          ? await AppDatabase.instance.getUserByEmail(email)
          : await AppDatabase.instance.getCurrentUser();
      if (user != null) {
        _userId = user.nUserId;
        if (user.nWeight != null && user.nWeight! > 0) {
          _userWeightKg = user.nWeight!;
        }
        this._safeNotifyListeners();
      }
    } catch (_) {
      debugPrint('WorkoutTrackingController: Failed to load signed-in user.');
    }
  }

  void _listenBackgroundLocation() {
    final service = FlutterBackgroundService();
    _bgLocationSub = service.on('updateLocation').listen((event) {
      if (_isDisposed || event == null || _status != WorkoutState.running) {
        return;
      }
      final lat = (event['latitude'] as num?)?.toDouble();
      final lng = (event['longitude'] as num?)?.toDouble();
      final speed = (event['speed'] as num?)?.toDouble() ?? 0.0;
      final accuracy = (event['accuracy'] as num?)?.toDouble() ?? 10.0;

      DateTime? bgTimestamp;
      if (event['timestamp'] != null) {
        bgTimestamp = DateTime.tryParse(event['timestamp'].toString());
      }

      if (lat != null && lng != null) {
        this._handleNewLocation(
          latitude: lat,
          longitude: lng,
          speedMs: speed,
          accuracy: accuracy,
          timestamp: bgTimestamp,
        );
      }
    });
  }
}
