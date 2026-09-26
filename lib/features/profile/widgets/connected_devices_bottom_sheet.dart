import 'package:flutter/material.dart';
import 'package:healthymate/core/services/theme_service.dart';

class ConnectedDevicesBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> connectedDevices;
  final Future<void> Function(String providerName) onAddDevice;
  final Future<void> Function(int integrationId, bool isActive) onToggleDevice;
  final Future<void> Function(int integrationId) onDeleteDevice;

  const ConnectedDevicesBottomSheet({
    super.key,
    required this.connectedDevices,
    required this.onAddDevice,
    required this.onToggleDevice,
    required this.onDeleteDevice,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.instance.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2822) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'อุปกรณ์ที่เชื่อมต่อ',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E2822),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white70 : Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E3D34) : const Color(0xFFF3F6F2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.watch_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ระบบเชื่อมต่ออุปกรณ์ภายนอก\n(จะเปิดให้บริการในเร็วๆ นี้)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E2822),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ทีมงานกำลังพัฒนาระบบซิงค์ข้อมูลก้าวเดิน อัตราการเต้นของหัวใจ จาก Apple HealthKit, Health Connect และ Smart Watch ยี่ห้อชั้นนำ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFFA0ACA0) : const Color(0xFF6F7A72),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF2E3D34) : Colors.grey.shade300,
                    foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: null, // ปิดการใช้งานปุ่มตามข้อกำหนด
                  child: const Text(
                    'ฟีเจอร์นี้อยู่ระหว่างการพัฒนา',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
