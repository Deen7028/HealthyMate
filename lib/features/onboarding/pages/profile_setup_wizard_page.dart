// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์ขั้นตอนเริ่มต้นใช้งานและตั้งค่าเป้าหมาย (profile setup wizard page)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/routine_state_notifier.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:healthymate/features/onboarding/models/onboarding_goal_template.dart';
import 'package:healthymate/features/onboarding/widgets/step2_body_metrics_view.dart';
import 'package:healthymate/features/onboarding/widgets/step3_primary_goal_view.dart';
import 'package:healthymate/main_app.dart';
import 'package:healthymate/shared/theme/app_theme.dart';

class ProfileSetupWizardPage extends StatefulWidget {
  final VoidCallback? onComplete;

  const ProfileSetupWizardPage({super.key, this.onComplete});

  @override
  State<ProfileSetupWizardPage> createState() => _ProfileSetupWizardPageState();
}

class _ProfileSetupWizardPageState extends State<ProfileSetupWizardPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0; // 0 = Body Metrics, 1 = Primary Goal

  // Step 1: Body Metrics
  String _gender = 'male';
  final TextEditingController _ageController = TextEditingController(text: '25');
  final TextEditingController _weightController = TextEditingController(text: '65.0');
  final TextEditingController _heightController = TextEditingController(text: '170.0');
  String _activityLevel = 'light';
  bool _isSavingMetrics = false;

  // Step 2: Primary Goal
  OnboardingGoalTemplate? _selectedGoal = OnboardingGoalTemplate.templates.first;
  bool _isSavingGoal = false;

  TbUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    try {
      final email = AuthService.instance.currentUserEmail;
      final user = email.isNotEmpty
          ? await AppDatabase.instance.getUserByEmail(email)
          : await AppDatabase.instance.getCurrentUser();

      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          if (user.sGender != null && user.sGender!.isNotEmpty) {
            _gender = user.sGender!;
          }
          if (user.nAge != null && user.nAge! > 0) {
            _ageController.text = user.nAge.toString();
          }
          if (user.nWeight != null && user.nWeight! > 0) {
            _weightController.text = user.nWeight!.toStringAsFixed(1);
          }
          if (user.nHeight != null && user.nHeight! > 0) {
            _heightController.text = user.nHeight!.toStringAsFixed(1);
          }
          if (user.sActivityLevel != null && user.sActivityLevel!.isNotEmpty) {
            _activityLevel = user.sActivityLevel!;
          }
        });
      }
    } catch (e) {
      debugPrint('ProfileSetupWizard: Error loading user data: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep < 1) {
      _pageController.animateToPage(
        _currentStep + 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _handleSaveBodyMetrics() async {
    final age = int.tryParse(_ageController.text.trim()) ?? 25;
    final weight = double.tryParse(_weightController.text.trim()) ?? 65.0;
    final height = double.tryParse(_heightController.text.trim()) ?? 170.0;

    if (age <= 0 || weight <= 0 || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลอายุ น้ำหนัก และส่วนสูงให้ถูกต้อง'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSavingMetrics = true;
    });

    try {
      final email = AuthService.instance.currentUserEmail;
      final user = _currentUser ??
          (email.isNotEmpty
              ? await AppDatabase.instance.getUserByEmail(email)
              : await AppDatabase.instance.getCurrentUser());

      if (user != null) {
        final updated = user.copyWith(
          sGender: _gender,
          nAge: age,
          nWeight: weight,
          nHeight: height,
          sActivityLevel: _activityLevel,
        );

        // บันทึกลง SQLite
        await AppDatabase.instance.updateUser(updated);
        _currentUser = updated;

        // อัปเดตลง Supabase / Remote Server ทันที
        unawaited(ProfileApiService.updateUserProfile(updated));
      }
    } catch (e) {
      debugPrint('ProfileSetupWizard: Error saving metrics: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingMetrics = false;
        });
        _nextPage();
      }
    }
  }

  Future<void> _handleFinishSetup() async {
    if (_selectedGoal == null) return;

    setState(() {
      _isSavingGoal = true;
    });

    try {
      final email = AuthService.instance.currentUserEmail;
      final user = _currentUser ??
          (email.isNotEmpty
              ? await AppDatabase.instance.getUserByEmail(email)
              : await AppDatabase.instance.getCurrentUser());

      if (user != null) {
        final template = _selectedGoal!;
        final deadline = DateTime.now().add(Duration(days: template.days));
        final deadlineStr = '${deadline.day}/${deadline.month}/${deadline.year}';
        final remainingText =
            'เป้าหมาย: 0 / ${template.targetValue == template.targetValue.toInt() ? template.targetValue.toInt() : template.targetValue.toStringAsFixed(1)} ${template.unit} (เหลือ ${template.days} วัน • สิ้นสุด $deadlineStr)';

        // 1. บันทึกลง SQLite
        await AppDatabase.instance.saveUserGoal(
          userId: user.nUserId,
          nRoutineId: 0,
          title: '${template.icon} ${template.title}',
          progress: 0.0,
          remainingText: remainingText,
          dtCreatedAt: DateTime.now().toIso8601String(),
        );

        // 2. ซิงค์ขึ้น Supabase / Remote Server
        unawaited(
          GoalApiService.saveMainGoalRemote(
            userId: user.nUserId,
            routineId: 0,
            title: '${template.icon} ${template.title}',
            progress: 0.0,
            remainingText: remainingText,
          ),
        );

        // 3. แจ้งเตือน RoutineStateNotifier ให้พร้อมแสดงผลบน Dashboard
        RoutineStateNotifier.instance.loadData(userId: user.nUserId);
      }

      if (!mounted) return;

      if (widget.onComplete != null) {
        widget.onComplete!();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainAppShell()),
        );
      }
    } catch (e) {
      debugPrint('ProfileSetupWizard finish error: $e');
      if (mounted) {
        setState(() {
          _isSavingGoal = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = AppTheme.getBackgroundColor(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        leading: _currentStep > 0
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
                onPressed: _previousPage,
              )
            : null,
        title: _buildStepIndicator(isDark),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _currentStep = index;
            });
          },
          children: [
            // Step 1: Body Metrics (เพศ, อายุ, น้ำหนัก, ส่วนสูง, ระดับกิจกรรม)
            Step2BodyMetricsView(
              gender: _gender,
              ageController: _ageController,
              weightController: _weightController,
              heightController: _heightController,
              selectedActivityLevel: _activityLevel,
              onGenderChanged: (val) => setState(() => _gender = val),
              onActivityLevelChanged: (val) => setState(() => _activityLevel = val),
              onNext: _handleSaveBodyMetrics,
              onBack: () {
                // หากอยู่ในขั้นตอนแรกแล้วกดย้อนกลับ ให้ข้ามไปหน้า Dashboard ได้
                if (widget.onComplete != null) {
                  widget.onComplete!();
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MainAppShell()),
                  );
                }
              },
              isLoading: _isSavingMetrics,
            ),
            // Step 2: Primary Goal Selection
            Step3PrimaryGoalView(
              selectedGoal: _selectedGoal,
              onSelectGoal: (goal) => setState(() => _selectedGoal = goal),
              onFinish: _handleFinishSetup,
              onBack: _previousPage,
              isLoading: _isSavingGoal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(2, (index) {
        final isCompleted = _currentStep >= index;
        final isCurrent = _currentStep == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isCurrent ? 28 : 10,
          height: 8,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppTheme.primaryGreen
                : (isDark ? Colors.white24 : Colors.black12),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
