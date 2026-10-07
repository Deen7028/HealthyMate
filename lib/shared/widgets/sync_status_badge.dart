import 'package:flutter/material.dart';
import 'package:healthymate/core/services/sync/sync_service.dart';

/// Widget แสดงแถบสถานะการซิงค์ข้อมูล และโหมด Offline-First
class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SyncService.instance,
      builder: (context, _) {
        final service = SyncService.instance;
        final isOnline = service.isOnline;
        final isSyncing = service.isSyncing;
        final pending = service.pendingCount;

        // ถ้าออนไลน์ปกติและไม่มีรายการค้างซิงค์ แสดงปุ่มไอคอนคลาวด์สีเขียวเรียบหรู
        Color bgColor;
        Color fgColor;
        IconData icon;
        String text;

        if (isSyncing) {
          bgColor = const Color(0xFFE8F0FE);
          fgColor = const Color(0xFF1A73E8);
          icon = Icons.sync_rounded;
          text = 'กำลังซิงค์...';
        } else if (!isOnline) {
          bgColor = const Color(0xFFFEF3D6);
          fgColor = const Color(0xFFB06000);
          icon = Icons.cloud_off_rounded;
          text = pending > 0 ? 'ออฟไลน์ (ค้าง $pending)' : 'ออฟไลน์';
        } else if (pending > 0) {
          bgColor = const Color(0xFFFFF3E0);
          fgColor = const Color(0xFFE65100);
          icon = Icons.cloud_upload_rounded;
          text = 'รอซิงค์ $pending';
        } else {
          bgColor = const Color(0xFFE6F4EA);
          fgColor = const Color(0xFF137333);
          icon = Icons.cloud_done_rounded;
          text = 'ซิงค์แล้ว';
        }

        return InkWell(
          onTap: () {
            // แตะเพื่อทดสอบและสั่งซิงค์ทันที
            service.syncPendingData();
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(service.statusMessage)),
                  ],
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                backgroundColor: fgColor,
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: fgColor.withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSyncing)
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                    ),
                  )
                else
                  Icon(icon, size: 14, color: fgColor),
                const SizedBox(width: 5),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
