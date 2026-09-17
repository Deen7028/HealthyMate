import 'package:flutter/material.dart';
import 'package:healthymate/core/services/theme_service.dart';

class ProfileHeaderCard extends StatelessWidget {
  final ImageProvider avatarProvider;
  final String name;
  final String email;
  final String goalTitle;
  final double goalProgress;
  final String goalRemainingText;
  final VoidCallback onAvatarTap;
  final VoidCallback onEditProfileTap;
  final VoidCallback onEditGoalTap;

  const ProfileHeaderCard({
    super.key,
    required this.avatarProvider,
    required this.name,
    required this.email,
    required this.goalTitle,
    required this.goalProgress,
    required this.goalRemainingText,
    required this.onAvatarTap,
    required this.onEditProfileTap,
    required this.onEditGoalTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode;

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
          // Big Circular Avatar with Edit Badge
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: onAvatarTap,
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E7DF), width: 3),
                      image: DecorationImage(
                        image: avatarProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: onAvatarTap,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E6339),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
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

          // เป้าหมายหลัก (Main Goal Card)
          GestureDetector(
            onTap: onEditGoalTap,
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F3EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.radar_rounded,
                          size: 18,
                          color: Color(0xFF2E6339),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'เป้าหมายหลัก',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5A6559),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    goalTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E2822),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Progress Bar & Percentage
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: goalProgress,
                            minHeight: 7,
                            backgroundColor: isDark ? Colors.black26 : const Color(0xFFE2E7DF),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF2E6339),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(goalProgress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF5A6559),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    goalRemainingText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8C968E),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
