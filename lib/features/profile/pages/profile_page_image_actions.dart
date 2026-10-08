part of 'profile_page.dart';

extension ProfilePageImageActions on _ProfilePageState {
  // ฟังก์ชันจัดการการเลือกและบันทึกรูปโปรไฟล์
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
                await this._handleImagePick(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_rounded, color: themePrimary),
              title: const Text('ถ่ายรูปด้วยกล้อง'),
              onTap: () async {
                Navigator.pop(ctx);
                await this._handleImagePick(ImageSource.camera);
              },
            ),
            if (_controller.currentUser?.sProfileImagePath.isNotEmpty == true)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                title: const Text(
                  'ลบรูปโปรไฟล์',
                  style: TextStyle(color: Colors.red),
                ),
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
        this._showPermissionDeniedDialog();
      }
    } catch (e) {
      debugPrint('Unexpected error picking image: $e');
      if (e.toString().toLowerCase().contains('denied') ||
          e.toString().toLowerCase().contains('permission')) {
        if (mounted) {
          this._showPermissionDeniedDialog();
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await Geolocator.openAppSettings();
            },
            child: const Text(
              'ไปที่การตั้งค่า',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
