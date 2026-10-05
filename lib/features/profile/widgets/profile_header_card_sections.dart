// ส่วนนี้อธิบายบทบาทของไฟล์: วิดเจ็ตย่อยของ UI ในฟีเจอร์โปรไฟล์ การตั้งค่า และบัญชีผู้ใช้ (profile header card sections)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'profile_header_card.dart';

extension _ProfileHeaderCardSections on ProfileHeaderCard {
  Widget _buildAvatar(bool isDark, Color primaryColor) {
    return Center(
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
                  color: isDark
                      ? const Color(0xFF3B4D41)
                      : const Color(0xFFE2E7DF),
                  width: 3,
                ),
                image: avatarProvider != null
                    ? DecorationImage(image: avatarProvider!, fit: BoxFit.cover)
                    : null,
              ),
              child: avatarProvider == null
                  ? const Icon(Icons.person, size: 58, color: Colors.white)
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
    );
  }

  Widget _buildIdentity(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: Color(0xFF6F7A72),
              ),
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
      ],
    );
  }
}
