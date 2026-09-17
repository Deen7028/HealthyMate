import 'package:flutter/material.dart';

class ConnectedDevicesBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> connectedDevices;
  final VoidCallback onDevicesUpdated;

  const ConnectedDevicesBottomSheet({
    super.key,
    required this.connectedDevices,
    required this.onDevicesUpdated,
  });

  @override
  State<ConnectedDevicesBottomSheet> createState() =>
      _ConnectedDevicesBottomSheetState();
}

class _ConnectedDevicesBottomSheetState
    extends State<ConnectedDevicesBottomSheet> {
  void _showAddDeviceDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'ค้นหาอุปกรณ์บลูทูธ (Bluetooth)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LinearProgressIndicator(color: Color(0xFF2E6339)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
              title: const Text('Polar H10 Heart Rate Sensor'),
              subtitle: const Text('สัญญาณ: ดีเยี่ยม (-45 dBm)'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E6339),
                ),
                onPressed: () {
                  setState(() {
                    widget.connectedDevices.add({
                      'id': 'd_${DateTime.now().millisecondsSinceEpoch}',
                      'name': 'Polar H10 Heart Rate Sensor',
                      'type': 'hr_monitor',
                      'icon': Icons.favorite_rounded,
                      'status': 'เชื่อมต่อแล้ว (พร้อมวัดค่าชีพจร)',
                      'isActive': true,
                    });
                  });
                  widget.onDevicesUpdated();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('เชื่อมต่อ Polar H10 สำเร็จ!'),
                      backgroundColor: Color(0xFF2E6339),
                    ),
                  );
                },
                child: const Text('เชื่อมต่อ', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount =
        widget.connectedDevices.where((d) => d['isActive'] == true).length;

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
            ...widget.connectedDevices.map((device) {
              final bool isActive = device['isActive'] ?? false;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F6F2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            device['icon'] as IconData,
                            color: const Color(0xFF2E6339),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device['name'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E2822),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isActive ? device['status'] : 'ตัดการเชื่อมต่อแล้ว',
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
                          activeTrackColor: const Color(0xFF2E6339),
                          activeThumbColor: Colors.white,
                          onChanged: (val) {
                            setState(() {
                              device['isActive'] = val;
                            });
                            widget.onDevicesUpdated();
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
                  foregroundColor: const Color(0xFF2E6339),
                  side: const BorderSide(color: Color(0xFF2E6339)),
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
