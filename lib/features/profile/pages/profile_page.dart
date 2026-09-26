import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/data_export_service.dart';
import 'package:healthymate/core/services/sync_service.dart';
import 'package:healthymate/core/services/theme_service.dart';
import 'package:healthymate/core/theme/app_theme.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';

// Components, Dialogs & Shared
import '../widgets/index.dart';
import 'package:healthymate/features/food_recognition/widgets/gemini_api_key_dialog.dart';
import 'package:healthymate/shared/dialogs/edit_goal_dialog.dart';

/// หน้าโปรไฟล์และการตั้งค่า HealthyMate
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  bool _isLocationEnabled = true;
  bool _isLoading = true;
  TbUser? _currentUser;

  // Hungarian Naming Conventions ตามมาตรฐานโปรเจกต์
  int nWorkoutCount = 0;
  int nActiveDays = 0;
  String sMainGoalTitle = '';
  double nGoalProgress = 0.0;
  String sGoalRemainingText = '';
  List<Map<String, dynamic>> lstConnectedDevices = [];
  String sSelectedUnit = 'Kilometers, Kilograms';
  String sGeminiApiKey = '';

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _checkLocationService();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLocationService();
    }
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

      // ป้องกันช่องโหว่ Data Leak: หาก Authentication ผิดพลาดหรือไม่พบบัญชี ให้ logout ทันที ห้าม fallback userId: 1
      if (user == null) {
        debugPrint('ProfilePage: No valid authenticated user found, forcing logout.');
        if (mounted) {
          await AuthService.instance.logout();
        }
        return;
      }

      final currentUserId = user.nUserId;

      // เพิ่มประสิทธิภาพด้วย Future.wait เพื่อดึงข้อมูลพร้อมกันแบบ Concurrent
      final results = await Future.wait([
        AppDatabase.instance.getWorkoutCount(userId: currentUserId),
        AppDatabase.instance.getUserGoal(currentUserId),
        AppDatabase.instance.getConnectedDevices(currentUserId),
        AppDatabase.instance.getUserUnitPreference(currentUserId),
        Geolocator.isLocationServiceEnabled(),
        AppDatabase.instance.getGeminiApiKey(currentUserId),
      ]);

      final count = results[0] as int;
      final goalData = results[1] as Map<String, dynamic>?;
      final devices = results[2] as List<Map<String, dynamic>>;
      final unit = results[3] as String;
      final locStatus = results[4] as bool;
      final apiKey = results[5] as String;

      // คำนวณวัน Active จากวันที่สร้างบัญชี (dtCreatedAt)
      final diff = DateTime.now().difference(user.dtCreatedAt).inDays;
      final days = diff >= 0 ? diff + 1 : 1;

      String goalTitle = '';
      double goalProgress = 0.0;
      String goalRemainingText = '';
      if (goalData != null) {
        goalTitle = goalData['sTitle']?.toString() ?? '';
        goalProgress = (goalData['nProgress'] as num?)?.toDouble() ?? 0.0;
        goalRemainingText = goalData['sRemainingText']?.toString() ?? '';
      }

      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLocationEnabled = locStatus;
          sSelectedUnit = unit;
          sGeminiApiKey = apiKey;
          nWorkoutCount = count;
          nActiveDays = days;
          sMainGoalTitle = goalTitle;
          nGoalProgress = goalProgress;
          sGoalRemainingText = goalRemainingText;
          lstConnectedDevices = devices;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// เลือกรูปและคัดลอกไฟล์รูปเก็บไว้ใน App Documents Directory ถาวร พร้อมระบบอัปโหลดซิงค์ขึ้น Cloud
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

  Future<void> _handleImagePick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked != null) {
        await _saveImageLocally(picked.path);
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

  /// บันทึกรูปลง Documents Directory ถาวร พร้อมลบรูปโปรไฟล์เดิมป้องกัน Storage Leak
  Future<void> _saveImageLocally(String tempPath) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final userId = _currentUser?.nUserId ?? 1;
      final rawExt = tempPath.contains('.') ? tempPath.split('.').last.toLowerCase() : 'jpg';
      final fileExtension = (rawExt.length <= 4 && !rawExt.contains('/')) ? rawExt : 'jpg';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final permanentPath = '${docDir.path}/profile_avatar_${userId}_$timestamp.$fileExtension';

      // 1. ลบรูปโปรไฟล์เดิมทิ้งก่อนเพื่อป้องกัน Storage Leak
      final oldPath = _currentUser?.sProfileImagePath ?? '';
      if (oldPath.isNotEmpty && !oldPath.startsWith('http')) {
        final oldFile = File(oldPath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      // 2. คัดลอกไฟล์จาก cache ไปยัง Documents ถาวร
      final tempFile = File(tempPath);
      await tempFile.copy(permanentPath);

      // 3. ลบ temp file ชั่วคราว
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      await _updateProfileImagePath(permanentPath);
    } catch (e) {
      debugPrint('Error saving image permanently: $e');
      await _updateProfileImagePath(tempPath);
    }
  }

  Future<void> _updateProfileImagePath(String path) async {
    if (_currentUser == null) return;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final updated = _currentUser!.copyWith(sProfileImagePath: path);

    // 1. อัปเดต SQLite ภายในเครื่อง
    await AppDatabase.instance.updateUser(updated);
    if (mounted) {
      setState(() {
        _currentUser = updated;
      });
    }

    // 2. ซิงค์ขึ้น Remote PHP Server
    String finalPathForRemote = path;
    if (path.isNotEmpty && !path.startsWith('http')) {
      final remoteUrl = await HealthApiService.uploadImage(path, type: 'profile');
      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        finalPathForRemote = remoteUrl;
      }
    }

    final remotePayload = updated.copyWith(sProfileImagePath: finalPathForRemote);
    final isSynced = await HealthApiService.updateUserProfile(remotePayload);

    if (!isSynced) {
      await SyncService.instance.updatePendingCount();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(path.isEmpty ? 'ลบรูปโปรไฟล์เรียบร้อยแล้ว' : 'บันทึกและซิงค์รูปโปรไฟล์เรียบร้อยแล้ว ☁️'),
          backgroundColor: primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// คืนค่า ImageProvider รองรับทั้งไฟล์ท้องถิ่น และ URL รูปถ่ายจาก Google Sign-In
  ImageProvider? _getAvatarImageProvider() {
    final path = _currentUser?.sProfileImagePath ?? '';
    if (path.isNotEmpty) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        return NetworkImage(path);
      }
      final file = File(path);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    return null;
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
    await _checkLocationService();
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
          selectedUnit: sSelectedUnit,
          onUnitSelected: (unit) async {
            setState(() {
              sSelectedUnit = unit;
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final messenger = ScaffoldMessenger.of(context);
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

            // 1. บันทึกลง SQLite
            await AppDatabase.instance.updateUser(updated);
            if (mounted) {
              setState(() {
                _currentUser = updated;
              });
            }

            final isSynced = await HealthApiService.updateUserProfile(updated);
            if (!isSynced) {
              await SyncService.instance.updatePendingCount();
            }

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
          }
        },
      ),
    );
  }

  void _showEditGoalDialog() {
    final user = _currentUser;
    if (user == null) return;
    final userId = user.nUserId;
    final primaryColor = Theme.of(context).colorScheme.primary;
    showDialog(
      context: context,
      builder: (dialogCtx) => EditGoalDialog(
        initialTitle: sMainGoalTitle,
        initialProgress: nGoalProgress,
        initialRemainingText: sGoalRemainingText,
        onSave: (title, progress, remainingText) async {
          await AppDatabase.instance.saveUserGoal(
            userId: userId,
            title: title,
            progress: progress,
            remainingText: remainingText,
          );
          if (mounted) {
            setState(() {
              sMainGoalTitle = title;
              nGoalProgress = progress;
              sGoalRemainingText = remainingText;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('อัปเดตเป้าหมายหลักเรียบร้อยแล้ว🎯'),
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
    final userId = _currentUser?.nUserId ?? 1;
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
              connectedDevices: lstConnectedDevices,
              onAddDevice: (providerName) async {
                await AppDatabase.instance.insertConnectedDevice(
                  userId: userId,
                  providerName: providerName,
                  isSynced: true,
                );
                final updated = await AppDatabase.instance.getConnectedDevices(userId);
                if (mounted) {
                  setState(() {
                    lstConnectedDevices = updated;
                  });
                }
                setModalState(() {});
              },
              onToggleDevice: (integrationId, isActive) async {
                await AppDatabase.instance.updateConnectedDeviceStatus(
                  integrationId: integrationId,
                  isSynced: isActive,
                );
                final updated = await AppDatabase.instance.getConnectedDevices(userId);
                if (mounted) {
                  setState(() {
                    lstConnectedDevices = updated;
                  });
                }
                setModalState(() {});
              },
              onDeleteDevice: (integrationId) async {
                await AppDatabase.instance.deleteConnectedDevice(integrationId);
                final updated = await AppDatabase.instance.getConnectedDevices(userId);
                if (mounted) {
                  setState(() {
                    lstConnectedDevices = updated;
                  });
                }
                setModalState(() {});
              },
            );
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

  Future<void> _handleExportCsv() async {
    final userId = _currentUser?.nUserId ?? 1;
    final path = await DataExportService.instance.exportDataToCsv(userId);
    if (path != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ส่งออกไฟล์ CSV สำเร็จเรียบร้อยแล้ว'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleExportPdf() async {
    final userId = _currentUser?.nUserId ?? 1;
    final path = await DataExportService.instance.exportDataToPdf(userId);
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
    final user = _currentUser;
    if (user == null) return;

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
      setState(() => _isLoading = true);

      // 1. เรียก API ทำลายข้อมูลบน Database Server
      await HealthApiService.deleteAccount(userId: user.nUserId, email: user.sEmail);

      // 2. ทำลายข้อมูล SQLite ในเครื่อง
      await AppDatabase.instance.deleteUserAccount(user.nUserId);

      // 3. เคลียร์ Google Session & App Session
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}

      if (mounted) {
        await AuthService.instance.logout();
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const LogoutConfirmDialog(),
    );

    if (confirmed == true && mounted) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('GoogleSignIn signOut error during logout: $e');
      }
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        await AuthService.instance.logout();
      }
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

    if (_isLoading) {
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

    final userName = (_currentUser != null && _currentUser!.sFullName.trim().isNotEmpty)
        ? _currentUser!.sFullName.trim()
        : 'ผู้ใช้งาน';
    final userEmail = (_currentUser != null && _currentUser!.sEmail.isNotEmpty)
        ? _currentUser!.sEmail
        : (AuthService.instance.currentUserEmail.isNotEmpty
            ? AuthService.instance.currentUserEmail
            : '');
    final avatarProvider = _getAvatarImageProvider();
    final activeDeviceCount = lstConnectedDevices
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
                goalTitle: sMainGoalTitle,
                goalProgress: nGoalProgress,
                goalRemainingText: sGoalRemainingText,
                onAvatarTap: _pickAndSaveProfileImage,
                onEditProfileTap: _showEditProfileDialog,
                onEditGoalTap: _showEditGoalDialog,
              ),

              const SizedBox(height: 16),

              // 3. Quick Stats (สถิติย่อ)
              QuickStatsCard(
                workoutCount: nWorkoutCount,
                activeDays: nActiveDays,
              ),

              const SizedBox(height: 20),

              // 4. Settings Section (การตั้งค่า)
              _buildSectionHeader('การตั้งค่า'),
              const SizedBox(height: 8),
              SettingsCard(
                isLocationEnabled: _isLocationEnabled,
                selectedUnit: sSelectedUnit,
                hasGeminiApiKey: sGeminiApiKey.isNotEmpty,
                onDarkModeChanged: (val) async {
                  await ThemeService.instance.setDarkMode(val);
                  setState(() {});
                },
                onLocationTap: _handleLocationTap,
                onUnitPickerTap: _showUnitPicker,
                onGeminiApiKeyTap: () {
                  GeminiApiKeyDialog.show(
                    context,
                    userId: _currentUser?.nUserId ?? 1,
                    currentKey: sGeminiApiKey,
                    onSaved: (newKey) {
                      setState(() {
                        sGeminiApiKey = newKey;
                      });
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
                onExportCsvTap: _handleExportCsv,
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
