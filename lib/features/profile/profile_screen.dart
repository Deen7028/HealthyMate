import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/theme_service.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';

// Components & Dialogs
import 'package:healthymate/features/profile/widgets/profile_top_bar.dart';
import 'package:healthymate/features/profile/widgets/profile_header_card.dart';
import 'package:healthymate/features/profile/widgets/quick_stats_card.dart';
import 'package:healthymate/features/profile/widgets/settings_card.dart';
import 'package:healthymate/features/profile/widgets/account_card.dart';
import 'package:healthymate/features/profile/widgets/profile_footer.dart';
import 'package:healthymate/features/profile/dialogs/edit_goal_dialog.dart';
import 'package:healthymate/features/profile/dialogs/edit_profile_dialog.dart';
import 'package:healthymate/features/profile/dialogs/unit_picker_bottom_sheet.dart';
import 'package:healthymate/features/profile/dialogs/connected_devices_bottom_sheet.dart';
import 'package:healthymate/features/profile/dialogs/personal_info_bottom_sheet.dart';
import 'package:healthymate/features/profile/dialogs/logout_confirm_dialog.dart';

/// หน้าโปรไฟล์และการตั้งค่า HealthyMate
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLocationEnabled = true;
  String _selectedUnit = 'Kilometers, Kilograms';
  TbUser? _currentUser;
  int _workoutCount = 142;
  int _activeDays = 312;

  // เป้าหมายหลัก (บันทึกและดึงจาก Database)
  String _mainGoalTitle = 'ฝึกซ้อมมาราธอน';
  double _goalProgress = 0.65;
  String _goalRemainingText = 'เหลือเวลาอีก 12 สัปดาห์';

  // อุปกรณ์ที่เชื่อมต่อ
  final List<Map<String, dynamic>> _connectedDevices = [
    {
      'id': 'd1',
      'name': 'Apple Watch Series 8',
      'type': 'watch',
      'icon': Icons.watch_rounded,
      'status': 'กำลังเชื่อมต่ออยู่ (ซิงค์ล่าสุด 5 นาทีที่แล้ว)',
      'isActive': true,
    },
    {
      'id': 'd2',
      'name': 'Smart Body Scale S2',
      'type': 'scale',
      'icon': Icons.monitor_weight_rounded,
      'status': 'เชื่อมต่อแล้ว (ซิงค์ล่าสุด เมื่อเช้า)',
      'isActive': true,
    },
  ];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkLocationService();
  }

  Future<void> _checkLocationService() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (mounted) {
        setState(() {
          _isLocationEnabled = enabled;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUserData() async {
    try {
      final email = AuthService.instance.currentUserEmail;
      TbUser? user;
      if (email.isNotEmpty) {
        user = await AppDatabase.instance.getUserByEmail(email);
      }
      user ??= await AppDatabase.instance.getUser(userId: 1);

      // โหลดสถิติ workout
      final workouts = await AppDatabase.instance.getWorkouts(userId: user?.nUserId ?? 1);
      final count = workouts.isNotEmpty ? workouts.length : 142;

      // คำนวณวัน Active
      int days = 312;
      if (user != null) {
        final diff = DateTime.now().difference(user.dtCreatedAt).inDays;
        if (diff > 0) days = diff;
      }

      // โหลดเป้าหมายจาก Database
      final goalData = await AppDatabase.instance.getUserGoal(user?.nUserId ?? 1);
      if (goalData != null) {
        _mainGoalTitle = goalData['sTitle'] ?? _mainGoalTitle;
        _goalProgress = (goalData['nProgress'] as num?)?.toDouble() ?? _goalProgress;
        _goalRemainingText = goalData['sRemainingText'] ?? _goalRemainingText;
      }

      // โหลดหน่วยวัดที่บันทึกไว้
      final unit = await AppDatabase.instance.getUserUnitPreference(user?.nUserId ?? 1);

      // ตรวจสอบสิทธิ์ Location
      final locStatus = await Geolocator.isLocationServiceEnabled();

      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLocationEnabled = locStatus;
          _selectedUnit = unit;
          _workoutCount = count;
          _activeDays = days;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    }
  }

  /// เลือกรูปและคัดลอกไฟล์รูปเก็บไว้ใน App Documents Directory ถาวร
  Future<void> _pickAndSaveProfileImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'เปลี่ยนรูปโปรไฟล์',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF2E6339)),
              title: const Text('เลือกจากแกลเลอรี'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (picked != null) {
                  await _saveImageLocally(picked.path);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2E6339)),
              title: const Text('ถ่ายรูปด้วยกล้อง'),
              onTap: () async {
                Navigator.pop(ctx);
                final picked = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (picked != null) {
                  await _saveImageLocally(picked.path);
                }
              },
            ),
            if (_currentUser?.sProfileImagePath.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('ลบรูปโปรไฟล์', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateProfileImagePath('');
                },
              ),
          ],
        ),
      ),
    );
  }

  /// บันทึกรูปลง Documents Directory เพื่อความถาวร
  Future<void> _saveImageLocally(String tempPath) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final userId = _currentUser?.nUserId ?? 1;
      final fileExtension = tempPath.split('.').last;
      final permanentPath = '${docDir.path}/profile_avatar_$userId.$fileExtension';

      // คัดลอกไฟล์จาก cache ไปยัง Documents ถาวร
      final tempFile = File(tempPath);
      await tempFile.copy(permanentPath);

      await _updateProfileImagePath(permanentPath);
    } catch (e) {
      debugPrint('Error saving image permanently: $e');
      await _updateProfileImagePath(tempPath);
    }
  }

  Future<void> _updateProfileImagePath(String path) async {
    if (_currentUser == null) return;
    final updated = _currentUser!.copyWith(sProfileImagePath: path);

    await AppDatabase.instance.updateUser(updated);
    setState(() {
      _currentUser = updated;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path.isEmpty ? 'ลบรูปโปรไฟล์แล้ว' : 'บันทึกรูปโปรไฟล์ถาวรเรียบร้อยแล้ว'),
          backgroundColor: const Color(0xFF2E6339),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  ImageProvider _getAvatarImageProvider() {
    final path = _currentUser?.sProfileImagePath ?? '';
    if (path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return const NetworkImage(
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80',
    );
  }

  Future<void> _handleLocationTap() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
    } else {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
      } else {
        await Geolocator.openLocationSettings();
      }
    }

    final enabled = await Geolocator.isLocationServiceEnabled();
    if (mounted) {
      setState(() {
        _isLocationEnabled = enabled;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enabled
              ? 'บริการตำแหน่งเปิดใช้งานแล้ว 📍'
              : 'บริการตำแหน่งยังไม่เปิดใช้งาน'),
          backgroundColor: const Color(0xFF2E6339),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showUnitPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return UnitPickerBottomSheet(
          selectedUnit: _selectedUnit,
          onUnitSelected: (unit) async {
            setState(() {
              _selectedUnit = unit;
            });
            await AppDatabase.instance.saveUserUnitPreference(
              _currentUser?.nUserId ?? 1,
              unit,
            );
          },
        );
      },
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(
        currentUser: _currentUser,
        onSave: ({
          required String firstName,
          required String lastName,
          required String gender,
          required int age,
          required double height,
          required double weight,
        }) async {
          if (firstName.isNotEmpty && _currentUser != null) {
            final updated = _currentUser!.copyWith(
              sFirstName: firstName,
              sLastName: lastName,
              nAge: age,
              nHeight: height,
              nWeight: weight,
              sGender: gender,
            );
            await AppDatabase.instance.updateUser(updated);
            setState(() {
              _currentUser = updated;
            });
          }
        },
      ),
    );
  }

  void _showEditGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => EditGoalDialog(
        initialTitle: _mainGoalTitle,
        initialProgress: _goalProgress,
        initialRemainingText: _goalRemainingText,
        onSave: (newTitle, newProgress, newRemaining) async {
          setState(() {
            _mainGoalTitle = newTitle;
            _goalProgress = newProgress;
            _goalRemainingText = newRemaining;
          });

          await AppDatabase.instance.saveUserGoal(
            userId: _currentUser?.nUserId ?? 1,
            title: newTitle,
            progress: newProgress,
            remainingText: newRemaining,
          );
        },
      ),
    );
  }

  void _showConnectedDevicesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ConnectedDevicesBottomSheet(
          connectedDevices: _connectedDevices,
          onDevicesUpdated: () {
            setState(() {});
          },
        );
      },
    );
  }

  void _showPersonalInfoBottomSheet() {
    final user = _currentUser;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return PersonalInfoBottomSheet(
          fullName: user?.sFullName.isNotEmpty == true ? user!.sFullName : 'Alex Morgan',
          email: user?.sEmail ?? AuthService.instance.currentUserEmail,
          gender: user?.sGender ?? 'female',
          age: user?.nAge ?? 26,
          height: user?.nHeight ?? 168.0,
          weight: user?.nWeight ?? 54.0,
          onEditTap: _showEditProfileDialog,
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const LogoutConfirmDialog(),
    );

    if (confirmed == true) {
      await AuthService.instance.logout();
    }
  }

  void _showPolicyDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E2822)),
        ),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(color: Color(0xFF5A6559), height: 1.5)),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E6339)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode;
    final userName = (_currentUser != null && _currentUser!.sFirstName.isNotEmpty)
        ? _currentUser!.sFullName
        : 'Alex Morgan';
    final userEmail = (_currentUser != null && _currentUser!.sEmail.isNotEmpty)
        ? _currentUser!.sEmail
        : (AuthService.instance.currentUserEmail.isNotEmpty
            ? AuthService.instance.currentUserEmail
            : 'alex.morgan@example.com');
    final avatarProvider = _getAvatarImageProvider();
    final activeDeviceCount =
        _connectedDevices.where((d) => d['isActive'] == true).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF131915) : const Color(0xFFF3F6F2),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top App Bar (Avatar + Title + Bell)
              ProfileTopBar(avatarProvider: avatarProvider),

              // 2. Main Profile Card (Avatar + Name + Email + Goal)
              ProfileHeaderCard(
                avatarProvider: avatarProvider,
                name: userName,
                email: userEmail,
                goalTitle: _mainGoalTitle,
                goalProgress: _goalProgress,
                goalRemainingText: _goalRemainingText,
                onAvatarTap: _pickAndSaveProfileImage,
                onEditProfileTap: _showEditProfileDialog,
                onEditGoalTap: _showEditGoalDialog,
              ),

              const SizedBox(height: 16),

              // 3. Quick Stats (สถิติย่อ)
              QuickStatsCard(
                workoutCount: _workoutCount,
                activeDays: _activeDays,
              ),

              const SizedBox(height: 20),

              // 4. Settings Section (การตั้งค่า)
              _buildSectionHeader('การตั้งค่า'),
              const SizedBox(height: 8),
              SettingsCard(
                isLocationEnabled: _isLocationEnabled,
                selectedUnit: _selectedUnit,
                onDarkModeChanged: (val) async {
                  await ThemeService.instance.setDarkMode(val);
                  setState(() {});
                },
                onLocationTap: _handleLocationTap,
                onUnitPickerTap: _showUnitPicker,
              ),

              const SizedBox(height: 20),

              // 5. Account Section (บัญชี)
              _buildSectionHeader('บัญชี'),
              const SizedBox(height: 8),
              AccountCard(
                activeDeviceCount: activeDeviceCount,
                onPersonalInfoTap: _showPersonalInfoBottomSheet,
                onConnectedDevicesTap: _showConnectedDevicesBottomSheet,
                onLogoutTap: _handleLogout,
              ),

              const SizedBox(height: 28),

              // 6. App Info Footer
              ProfileFooter(
                onPrivacyPolicyTap: () {
                  _showPolicyDialog(
                    'นโยบายความเป็นส่วนตัว (Privacy Policy)',
                    'HealthyMate ให้ความสำคัญสูงสุดกับความเป็นส่วนตัวของข้อมูลสุขภาพและพิกัดการออกกำลังกายของคุณ ข้อมูลทั้งหมดจะถูกเก็บรักษาอย่างปลอดภัยในอุปกรณ์ของคุณ และจะไม่มีการส่งต่อข้อมูลส่วนบุคคลไปยังบุคคลภายนอกโดยไม่ได้รับอนุญาต',
                  );
                },
                onTermsTap: () {
                  _showPolicyDialog(
                    'ข้อกำหนดและเงื่อนไขการใช้งาน (Terms of Service)',
                    'การใช้งานแอปพลิเคชัน HealthyMate ถือว่าท่านยอมรับการประมวลผลข้อมูลทางสถิติการออกกำลังกาย คำแนะนำด้านสุขภาพและการคำนวณ BMI/TDEE เป็นข้อมูลเพื่อการดูแลสุขภาพเบื้องต้นเท่านั้น มิได้ใช้แทนคำแนะนำของแพทย์ผู้เชี่ยวชาญ',
                  );
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5A6559),
        ),
      ),
    );
  }
}
