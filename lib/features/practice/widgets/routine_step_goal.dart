import 'package:flutter/material.dart';

class RoutineStepGoal extends StatelessWidget {
  final TextEditingController targetController;
  final TextEditingController unitController;
  final String? selectedLinkedWorkout;
  final String? autoDetected;
  final bool showGpsSyncOption;
  final ValueChanged<bool> onToggleAutoLink;
  final ValueChanged<String> onSelectUnit;

  const RoutineStepGoal({
    super.key,
    required this.targetController,
    required this.unitController,
    required this.selectedLinkedWorkout,
    required this.autoDetected,
    this.showGpsSyncOption = true,
    required this.onToggleAutoLink,
    required this.onSelectUnit,
  });

  @override
  Widget build(BuildContext context) {
    final isAutoLinked =
        selectedLinkedWorkout != null && selectedLinkedWorkout!.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Step 2: เป้าหมาย & เชื่อมโยง GPS ออกกำลังกาย 🔗',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E281F),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'กำหนดเป้าหมายเชิงปริมาณ',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E9E0)),
            ),
            child: Row(
              children: [
                _buildQuickUnitButton('กม.', 'ระยะทาง'),
                _buildQuickUnitButton('นาที', 'เวลา'),
                _buildQuickUnitButton('ครั้ง', 'จำนวน'),
                _buildQuickUnitButton('มล.', 'โภชนาการ'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'เป้าหมายต่อวัน *',
                    hintText: 'เช่น 5, 30, 2000',
                    prefixIcon: const Icon(Icons.flag_rounded,
                        color: Color(0xFF2E5327)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: unitController,
                  decoration: InputDecoration(
                    labelText: 'หน่วยวัด',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showGpsSyncOption) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isAutoLinked
                    ? const Color(0xFFE8F3EB)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isAutoLinked
                      ? const Color(0xFF2E5327)
                      : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.link_rounded,
                              color: isAutoLinked
                                  ? const Color(0xFF2E5327)
                                  : Colors.grey,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '🔗 เชื่อมโยงข้อมูล GPS ออกกำลังกายอัตโนมัติ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isAutoLinked
                                      ? const Color(0xFF2E5327)
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isAutoLinked,
                        onChanged: onToggleAutoLink,
                        activeThumbColor: const Color(0xFF2E5327),
                      ),
                    ],
                  ),
                  if (isAutoLinked) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFCBE3D3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt_rounded,
                              size: 16, color: Colors.orange),
                          const SizedBox(width: 6),
                          Text(
                            'ตรวจจับกีฬา: "${selectedLinkedWorkout ?? autoDetected}" Auto-GPS Sync',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E5327),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickUnitButton(String unit, String label) {
    final isSelected = unitController.text.trim() == unit;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelectUnit(unit),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2E5327) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(
                unit,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF334155),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
