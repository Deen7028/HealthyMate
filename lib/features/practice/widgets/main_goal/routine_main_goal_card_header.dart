part of 'routine_main_goal_card.dart';
// ส่วนหัวของการ์ดเป้าหมายหลัก (Header: ไอคอน, ชื่อเป้าหมาย, ปุ่มเมนูตัวเลือก)
extension _RoutineMainGoalCardHeader on RoutineMainGoalCard {
  Widget _buildPinnedGoalHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 12, right: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: darkGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '🚩 กิจวัตรจากเป้าหมายหลัก',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (value) {
                  if (value == 'unpin') onUnpin();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'unpin',
                    child: Row(
                      children: [
                        Icon(Icons.close, color: Colors.grey, size: 20),
                        SizedBox(width: 8),
                        Text('ยกเลิกเป้าหมายหลัก'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
