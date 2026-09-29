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
      debugPrint('ProfilePage: No valid authenticated user found, forcing logout.');
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

  /// เลือกรูปโปรไฟล์ผ่าน BottomSheet
  Future<void> _pickAndSaveProfileImage() async {
    final themePrimary = Theme.of(context).colorScheme.primary;

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
                  color: themePrimary,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_rounded, color: themePrimary),
              title: const Text('เลือกจากแกลเลอรี'),
              onTap: () async {
                Navigator.pop(ctx);
                await _handleImagePick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: themePrimary),
              title: const Text('ถ่ายรูปด้วยกล้อง'),
              onTap: () async {
                Navigator.pop(ctx);
                await _handleImagePick(ImageSource.camera);
              },
            ),
            if (_controller.currentUser?.sProfileImagePath.isNotEmpty == true)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                title: const Text('ลบรูปโปรไฟล์', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _controller.updateProfileImagePath('');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('ลบรูปโปรไฟล์เรียบร้อยแล้ว'),
                        backgroundColor: themePrimary,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleImagePick(ImageSource source) async {
    try {
      final success = await _controller.handleImagePick(source);
      if (success && mounted) {
        final themePrimary = Theme.of(context).colorScheme.primary;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('บันทึกและซิงค์รูปโปรไฟล์เรียบร้อยแล้ว ☁️'),
            backgroundColor: themePrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on PlatformException catch (pe) {
      debugPrint('Permission error picking image: $pe');
      if (mounted) {
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      debugPrint('Unexpected error picking image: $e');
      if (e.toString().toLowerCase().contains('denied') ||
          e.toString().toLowerCase().contains('permission')) {
        if (mounted) {
          _showPermissionDeniedDialog();
        }
      }
    }
  }

  void _showPermissionDeniedDialog() {
    final themePrimary = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text(
              'ไม่ได้รับสิทธิ์เข้าถึง',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'แอปพลิเคชันต้องการสิทธิ์การเข้าถึงกล้องหรือคลังภาพเพื่อเปลี่ยนรูปโปรไฟล์ของคุณ กรุณาอนุญาตสิทธิ์ในการตั้งค่าของอุปกรณ์',
          style: TextStyle(fontSize: 14, color: Color(0xFF5A6559), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: themePrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openAppSettings();
            },
            child: const Text('ไปที่การตั้งค่า', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
          selectedUnit: _controller.selectedUnit,
          onUnitSelected: (unit) async {
            await _controller.saveUserUnitPreference(unit);
          },
        );
      },
    );
  }

  void _showEditProfileDialog() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(
        currentUser: _controller.currentUser,
        onSave: ({
          required String firstName,
          required String lastName,
          required String gender,
          required int age,
          required double height,
          required double weight,
        }) async {
          final isSynced = await _controller.updateProfileInfo(
            firstName: firstName,
            lastName: lastName,
            gender: gender,
            age: age,
            height: height,
            weight: weight,
          );

          if (mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(isSynced
                    ? 'อัปเดตและซิงค์ข้อมูลโปรไฟล์เรียบร้อยแล้ว ☁️'
                    : 'บันทึกข้อมูลในเครื่องเรียบร้อยแล้ว (จะซิงค์เมื่อมีเน็ต)'),
                backgroundColor: primaryColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
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
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return ConnectedDevicesBottomSheet(
              connectedDevices: _controller.connectedDevices,
              onAddDevice: (providerName) async {
                await _controller.addConnectedDevice(providerName);
                setModalState(() {});
              },
              onToggleDevice: (integrationId, isActive) async {
                await _controller.toggleConnectedDeviceStatus(integrationId, isActive);
                setModalState(() {});
              },
              onDeleteDevice: (integrationId) async {
                await _controller.deleteConnectedDevice(integrationId);
                setModalState(() {});
              },
            );
          },
        );
      },
    );
  }

  void _showPersonalInfoBottomSheet() {
    final user = _controller.currentUser;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return PersonalInfoBottomSheet(
          fullName: user?.sFullName ?? '',
          email: user?.sEmail ?? AuthService.instance.currentUserEmail,
          gender: user?.sGender ?? 'male',
          age: user?.nAge ?? 0,
          height: user?.nHeight ?? 0.0,
          weight: user?.nWeight ?? 0.0,
          onEditTap: _showEditProfileDialog,
        );
      },
    );
  }

  Future<void> _handleExportPdf() async {
    final path = await _controller.exportPdf();
    if (path != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ส่งออกรายงานสรุป PDF สำเร็จเรียบร้อยแล้ว'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('ลบบัญชีและข้อมูลทั้งหมด', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 18)),
          ],
        ),
        content: const Text(
          'คำเตือน: การลบบัญชีจะเป็นการทำลายประวัติสุขภาพ สถิติการออกกำลังกาย และข้อมูลทั้งหมดถาวรตามกฎหมาย PDPA/GDPR โดยไม่สามารถกู้คืนได้ คุณแน่ใจหรือไม่?',
          style: TextStyle(fontSize: 14, color: Color(0xFF5A6559), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบบัญชีถาวร', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final deleted = await _controller.deleteAccount();
      if (!deleted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบบัญชีบนเซิร์ฟเวอร์ไม่สำเร็จ กรุณาลองใหม่')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const LogoutConfirmDialog(),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      await _controller.logout();
    }
  }

  void _showPolicyDialog(String title, String content) {
    final themePrimary = Theme.of(context).colorScheme.primary;
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
            style: ElevatedButton.styleFrom(backgroundColor: themePrimary),
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_controller.isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF131915) : const Color(0xFFF3F6F2),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primaryColor),
                const SizedBox(height: 16),
                const Text(
                  'กำลังโหลดข้อมูลโปรไฟล์...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5A6559),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = _controller.currentUser;
    final userName = (user != null && user.sFullName.trim().isNotEmpty)
        ? user.sFullName.trim()
        : 'ผู้ใช้งาน';
    final userEmail = (user != null && user.sEmail.isNotEmpty)
        ? user.sEmail
        : (AuthService.instance.currentUserEmail.isNotEmpty
            ? AuthService.instance.currentUserEmail
            : '');
    final avatarProvider = _controller.getAvatarImageProvider();
    final activeDeviceCount = _controller.connectedDevices
        .where((d) => (d['isSynced'] as num?)?.toInt() == 1)
        .length;

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
                goalTitle: _controller.mainGoalTitle,
                goalProgress: _controller.goalProgress,
                goalRemainingText: _controller.goalRemainingText,
                isUploadingImage: _controller.isUploadingImage,
                onAvatarTap: _pickAndSaveProfileImage,
                onEditProfileTap: _showEditProfileDialog,
                onGoalTap: widget.onNavigateToPractice,
              ),

              const SizedBox(height: 16),

              // 3. Quick Stats (สถิติย่อ)
              QuickStatsCard(
                workoutCount: _controller.workoutCount,
                activeDays: _controller.activeDays,
              ),

              const SizedBox(height: 20),

              // 4. Settings Section (การตั้งค่า)
              _buildSectionHeader('การตั้งค่า'),
              const SizedBox(height: 8),
              SettingsCard(
                isLocationEnabled: _controller.isLocationEnabled,
                selectedUnit: _controller.selectedUnit,
                hasGeminiApiKey: _controller.geminiApiKey.isNotEmpty,
                onDarkModeChanged: (val) async {
                  await ThemeService.instance.setDarkMode(val);
                  setState(() {});
                },
                onLocationTap: () async {
                  await _controller.handleLocationTap();
                },
                onUnitPickerTap: _showUnitPicker,
                onGeminiApiKeyTap: () {
                  if (user == null) return;
                  GeminiApiKeyDialog.show(
                    context,
                    userId: user.nUserId,
                    currentKey: _controller.geminiApiKey,
                    onSaved: (newKey) {
                      _controller.updateGeminiApiKey(newKey);
                    },
                  );
                },
              ),

              const SizedBox(height: 20),

              // 5. Account Section (บัญชี)
              _buildSectionHeader('บัญชี'),
              const SizedBox(height: 8),
              AccountCard(
                activeDeviceCount: activeDeviceCount,
                onPersonalInfoTap: _showPersonalInfoBottomSheet,
                onConnectedDevicesTap: _showConnectedDevicesBottomSheet,
                onExportPdfTap: _handleExportPdf,
                onDeleteAccountTap: _handleDeleteAccount,
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
