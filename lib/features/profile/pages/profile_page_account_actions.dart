// ส่วนนี้อธิบายบทบาทของไฟล์: หน้าจอหลัก ในฟีเจอร์โปรไฟล์ การตั้งค่า และบัญชีผู้ใช้ (profile page account actions)
// คอมเมนท์ภาษาไทยถูกใส่ไว้เป็นส่วนๆ เพื่อช่วยไล่ flow โดยไม่เปลี่ยนพฤติกรรมเดิมของโค้ด

part of 'profile_page.dart';

extension ProfilePageAccountActions on _ProfilePageState {
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
            Text(
              'ลบบัญชีและข้อมูลทั้งหมด',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 18,
              ),
            ),
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
            child: const Text(
              'ลบบัญชีถาวร',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final deleted = await _controller.deleteAccount();
      if (!deleted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ลบบัญชีบนเซิร์ฟเวอร์ไม่สำเร็จ กรุณาลองใหม่'),
          ),
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
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E2822),
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(color: Color(0xFF5A6559), height: 1.5),
          ),
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
}
