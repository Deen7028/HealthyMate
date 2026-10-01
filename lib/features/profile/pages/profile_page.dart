import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/routine_state_notifier.dart';
import 'package:healthymate/core/services/theme_service.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/features/profile/controllers/profile_controller.dart';

// Components, Dialogs & Shared
import '../widgets/index.dart';
import 'package:healthymate/features/food_recognition/widgets/gemini_api_key_dialog.dart';

/// หน้าโปรไฟล์และการตั้งค่า HealthyMate
part 'profile_page_image_actions.dart';
part 'profile_page_sheets.dart';
part 'profile_page_account_actions.dart';
part 'profile_page_content.dart';

class ProfilePage extends StatefulWidget {
  final bool isActive;
  final VoidCallback? onNavigateToPractice;

  const ProfilePage({
    super.key,
    this.isActive = true,
    this.onNavigateToPractice,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  late final ProfileController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ProfileController();
    _controller.addListener(_onControllerChanged);
    RoutineStateNotifier.instance.addListener(_onRoutineStateChanged);
    _initData();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onRoutineStateChanged() {
    if (mounted) {
      _controller.loadUserData();
    }
  }

  Future<void> _initData() async {
    final hasValidUser = await _controller.loadUserData();
    if (!hasValidUser && mounted) {
      debugPrint(
        'ProfilePage: No valid authenticated user found, forcing logout.',
      );
      await AuthService.instance.logout();
    }
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.loadUserData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RoutineStateNotifier.instance.removeListener(_onRoutineStateChanged);
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.checkLocationService();
    }
  }

  @override
  Widget build(BuildContext context) => _buildProfilePage(context);
}
