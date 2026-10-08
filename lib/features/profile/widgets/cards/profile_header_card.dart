import 'package:flutter/material.dart';
import 'package:healthymate/core/services/theme_service.dart';

part 'profile_header_card_sections.dart';
part 'profile_header_card_goal.dart';
// การ์ดโปรไฟล์
class ProfileHeaderCard extends StatelessWidget {
  final ImageProvider? avatarProvider;
  final String name;
  final String email;
  final String goalTitle;
  final double goalProgress;
  final String goalRemainingText;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditProfileTap;
  final VoidCallback? onGoalTap;
  final bool isUploadingImage;

  const ProfileHeaderCard({
    super.key,
    this.avatarProvider,
    required this.name,
    required this.email,
    required this.goalTitle,
    required this.goalProgress,
    required this.goalRemainingText,
    required this.onAvatarTap,
    required this.onEditProfileTap,
    this.onGoalTap,
    this.isUploadingImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final hasGoal = goalTitle.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // รูปโปรไฟล์
          _buildAvatar(isDark, primaryColor),
          const SizedBox(height: 16),
          _buildIdentity(isDark),

          const SizedBox(height: 20),

          // เป้าหมายหลัก 
          _buildGoalCard(isDark, primaryColor, hasGoal),
        ],
      ),
    );
  }
}
