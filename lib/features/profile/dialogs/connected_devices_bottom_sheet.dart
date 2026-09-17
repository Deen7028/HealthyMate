import 'package:flutter/material.dart';

class ConnectedDevicesBottomSheet extends StatefulWidget {
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
  State<ConnectedDevicesBottomSheet> createState() =>
      _ConnectedDevicesBottomSheetState();
}

class _ConnectedDevicesBottomSheetState
    extends State<ConnectedDevicesBottomSheet> {
  final TextEditingController _deviceCtrl = TextEditingController();

  @override
  void dispose() {
    _deviceCtrl.dispose();
    super.dispose();
  }

  void _showAddDeviceDialog() {
    _deviceCtrl.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'เพิ่มอุปกรณ์ที่เชื่อมต่อ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E2822)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ระบุชื่ออุปกรณ์สุขภาพ เช่น Smart Watch หรือเครื่องชั่งน้ำหนักอัจฉริยะ',
              style: TextStyle(fontSize: 13, color: Color(0xFF5A6559)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _deviceCtrl,
              decoration: InputDecoration(
                hintText: 'เช่น Apple Watch Series 8 หรือ Garmin Forerunner',
                labelText: 'ชื่ออุปกรณ์',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final name = _deviceCtrl.text.trim();
              if (name.isNotEmpty) {
                await widget.onAddDevice(name);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('เพิ่ม $name เชื่อมต่อกับระบบแล้ว'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('watch') || lower.contains('band') || lower.contains('fitbit') || lower.contains('garmin')) {
      return Icons.watch_rounded;
    } else if (lower.contains('scale') || lower.contains('weight') || lower.contains('ชั่ง')) {
      return Icons.monitor_weight_rounded;
    } else if (lower.contains('heart') || lower.contains('polar') || lower.contains('pulse')) {
      return Icons.favorite_rounded;
    }
    return Icons.devices_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = widget.connectedDevices.where((d) => (d['isSynced'] as num?)?.toInt() == 1).length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'อุปกรณ์ที่เชื่อมต่อ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2822),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E7DF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$activeCount Active',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5A6559),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.connectedDevices.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6F2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.devices_other_rounded, size: 40, color: Color(0xFF8C968E)),
                    SizedBox(height: 10),
                    Text(
                      'ยังไม่มีอุปกรณ์ที่เชื่อมต่อในระบบ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A6559),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'แตะปุ่มด้านล่างเพื่อผูกอุปกรณ์สุขภาพเข้ากับบัญชีของคุณ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8C968E),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...widget.connectedDevices.map((device) {
                final int id = (device['nIntegrationId'] as num?)?.toInt() ?? 0;
                final bool isActive = (device['isSynced'] as num?)?.toInt() == 1;
                final String name = device['sProviderName']?.toString() ?? 'อุปกรณ์';
                final String? lastSynced = device['dtLastSyncedAt']?.toString();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F6F2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getDeviceIcon(name),
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E2822),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isActive
                                      ? (lastSynced != null ? 'เชื่อมต่อแล้ว' : 'เปิดใช้งาน')
                                      : 'ปิดการเชื่อมต่อ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isActive
                                        ? const Color(0xFF6F7A72)
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isActive,
                            activeTrackColor: Theme.of(context).colorScheme.primary,
                            activeThumbColor: Colors.white,
                            onChanged: (val) async {
                              await widget.onToggleDevice(id, val);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                            onPressed: () async {
                              await widget.onDeleteDevice(id);
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                );
              }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  side: BorderSide(color: Theme.of(context).colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _showAddDeviceDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('ค้นหาและเพิ่มอุปกรณ์ใหม่'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
