import 'package:flutter/material.dart';
import 'package:healthymate/core/services/theme_service.dart';

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
          // Big Circular Avatar with Edit Badge & Loading Indicator
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: isUploadingImage ? null : onAvatarTap,
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor,
                      border: Border.all(
                        color: isDark ? const Color(0xFF3B4D41) : const Color(0xFFE2E7DF),
                        width: 3,
                      ),
                      image: avatarProvider != null
                          ? DecorationImage(
                              image: avatarProvider!,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: avatarProvider == null
                        ? const Icon(
                            Icons.person,
                            size: 58,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                if (isUploadingImage)
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: isUploadingImage ? null : onAvatarTap,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E2822) : Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // User Name with edit icon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E2822),
                ),
              ),
              IconButton(
                onPressed: onEditProfileTap,
                icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF6F7A72)),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),

          // User Email
          Text(
            email,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6F7A72),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 20),

          // เป้าหมายหลัก (Main Goal Card - แสดงข้อมูลกระจกเงา Read-only แตะเพื่อไปหน้ากิจวัตร)
          InkWell(
            onTap: onGoalTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF27342C) : const Color(0xFFF7F8F4),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? const Color(0xFF3B4D41) : const Color(0xFFE2E7DF),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.radar_rounded,
                              size: 18,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'เป้าหมายหลัก',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFFB0BEB3) : const Color(0xFF5A6559),
                            ),
                          ),
                        ],
                      ),
                      if (onGoalTap != null)
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF6F7A72),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasGoal ? goalTitle : 'ยังไม่ได้กำหนดเป้าหมาย',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: hasGoal
                          ? (isDark ? Colors.white : const Color(0xFF1E2822))
                          : (isDark ? Colors.grey.shade400 : const Color(0xFF8C968E)),
                    ),
                  ),
                  if (hasGoal) ...[
                    const SizedBox(height: 10),
                    // Progress Bar & Percentage
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: goalProgress.clamp(0.0, 1.0),
                              minHeight: 7,
                              backgroundColor: isDark ? Colors.black26 : const Color(0xFFE2E7DF),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(goalProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFB0BEB3) : const Color(0xFF5A6559),
                          ),
                        ),
                      ],
                    ),
                    if (goalRemainingText.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        goalRemainingText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8C968E),
                        ),
                      ),
                    ],
                  ] else ...[
                    const SizedBox(height: 6),
                    Text(
                      'แตะที่นี่เพื่อตั้งเป้าหมายสุขภาพหรือการออกกำลังกายของคุณ',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
