import 'package:flutter/material.dart';
import 'models/routine_item.dart';
import 'widgets/add_routine_dialog.dart';

class MyRoutinesPage extends StatefulWidget {
  const MyRoutinesPage({super.key});

  @override
  State<MyRoutinesPage> createState() => _MyRoutinesPageState();
}

class _MyRoutinesPageState extends State<MyRoutinesPage> {
  final Color primaryGreen = const Color(0xFF0F9C58);
  final Color darkGreen = const Color(0xFF006432);
  final Color lightBg = const Color(0xFFF7F9FB);
  final Color cardGreenBg = const Color(0xFFE8F5E9);

  bool _isWarmupChecked = false;
  bool _isCooldownChecked = true;
  final List<RoutineItem> _customRoutines = [];
  RoutineItem? _pinnedMainGoal;

  Future<void> _openAddRoutineDialog() async {
    final RoutineItem? newRoutine = await showModalBottomSheet<RoutineItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const AddRoutineDialog(),
    );

    if (newRoutine != null) {
      setState(() => _customRoutines.add(newRoutine));
      _showSnackBar('เพิ่ม "${newRoutine.title}" ในกิจวัตรสำเร็จ!');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: darkGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // --- เมนู 3 จุด (Popup Menu) ---
  Widget _buildThreeDotsMenu({
    required VoidCallback onPin,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    bool isPinned = false,
  }) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'pin') onPin();
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pin',
          child: Row(
            children: [
              Icon(isPinned ? Icons.push_pin_outlined : Icons.push_pin, color: primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(isPinned ? 'เลิกปักหมุดเป้าหมายหลัก' : 'ปักหมุดเป็นเป้าหมายหลัก'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('แก้ไข'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('ลบ'),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              if (_pinnedMainGoal != null)
                _buildMainGoalCard()
              else
                _buildDefaultMainGoalCard(),
              
              const SizedBox(height: 24),
              _buildDailyRoutinesHeader(),
              const SizedBox(height: 16),

              // ☀️ ช่วงเช้า
              _buildTimeBlockHeader('☀️ ช่วงเช้า (Morning)', '06:00 - 11:00'),
              _buildRoutineCard(
                icon: Icons.water_drop,
                iconBg: Colors.blue.shade50,
                iconColor: Colors.blue,
                title: 'ดื่มน้ำ',
                badgeText: '60%',
                subtitle: 'เป้าหมายเช้าถึงบ่าย: 2.5 ลิตร',
                actionWidget: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text('+250 ml', style: TextStyle(color: Colors.white, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                ),
                progressText: '1.5 / 2.5 ลิตร (60%)',
                progressValue: 0.6,
                progressColor: Colors.blue.shade700,
                onPin: () => _showSnackBar('ปักหมุด "ดื่มน้ำ"'),
                onEdit: () => _showSnackBar('แก้ไข "ดื่มน้ำ"'),
                onDelete: () => _showSnackBar('ลบ "ดื่มน้ำ"'),
              ),

              const SizedBox(height: 20),

              // 🏃 ระหว่างวัน
              _buildTimeBlockHeader('🏃 ระหว่างวัน (Afternoon / Active)', '12:00 - 18:00'),
              _buildRoutineCard(
                icon: Icons.directions_walk,
                iconBg: Colors.red.shade50,
                iconColor: Colors.red.shade400,
                title: 'เดินสะสม',
                badgeText: '60%',
                badgeColor: Colors.red.shade100,
                badgeTextColor: Colors.red.shade800,
                subtitle: 'เป้าหมายการขยับร่างกาย: 10,000 ก้าว',
                actionWidget: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.sync, size: 16, color: Colors.blueGrey),
                  label: const Text('ซิงก์ก้าว', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                ),
                progressText: '6,000 / 10,000 ก้าว (60%)',
                progressValue: 0.6,
                progressColor: Colors.red.shade800,
                onPin: () => _showSnackBar('ปักหมุด "เดินสะสม"'),
                onEdit: () => _showSnackBar('แก้ไข "เดินสะสม"'),
                onDelete: () => _showSnackBar('ลบ "เดินสะสม"'),
              ),

              const SizedBox(height: 20),

              // 🌙 ก่อนนอน
              _buildTimeBlockHeader('🌙 ก่อนนอน (Night / Wind Down)', '21:00 - 23:00'),
              _buildRoutineCard(
                icon: Icons.bedtime,
                iconBg: Colors.indigo.shade50,
                iconColor: Colors.indigo,
                title: 'นอนหลับ',
                badgeText: '75%',
                badgeColor: Colors.indigo.shade100,
                badgeTextColor: Colors.indigo.shade800,
                subtitle: 'พักผ่อนอย่างมีคุณภาพ: เป้าหมาย 8 ชม.',
                actionWidget: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.alarm, size: 16, color: Colors.blueGrey),
                  label: const Text('ตั้งเวลา', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                ),
                progressText: '6 / 8 ชม. (75%)',
                progressValue: 0.75,
                progressColor: Colors.indigo.shade400,
                onPin: () => _showSnackBar('ปักหมุด "นอนหลับ"'),
                onEdit: () => _showSnackBar('แก้ไข "นอนหลับ"'),
                onDelete: () => _showSnackBar('ลบ "นอนหลับ"'),
              ),

              if (_customRoutines.isNotEmpty) ...[
                const SizedBox(height: 20),
                _buildTimeBlockHeader('⭐ กิจวัตรที่เพิ่มใหม่', 'จัดการโดยคุณ'),
                ..._customRoutines.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildCustomRoutineCard(item),
                  ),
                ),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddRoutineDialog,
        backgroundColor: darkGreen,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: lightBg,
      elevation: 0,
      leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black87), onPressed: () {}),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('กิจวัตรของฉัน', style: TextStyle(color: Color(0xFF006432), fontWeight: FontWeight.bold, fontSize: 18)),
          Text('(My Routines)', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_active, color: Colors.blueGrey, size: 20), onPressed: () {}),
        const Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: CircleAvatar(radius: 16, backgroundColor: Color(0xFF0F9C58), child: Icon(Icons.person, color: Colors.white, size: 18)),
        ),
      ],
    );
  }

  Widget _buildMainGoalCard() {
    return _buildBaseMainGoalCard(
      title: _pinnedMainGoal!.title,
      subtitle: 'เป้าหมาย: ${_pinnedMainGoal!.targetValue.toInt()} ${_pinnedMainGoal!.unit}',
      iconData: _pinnedMainGoal!.iconData,
      progress: '${_pinnedMainGoal!.currentValue.toInt()} / ${_pinnedMainGoal!.targetValue.toInt()} ${_pinnedMainGoal!.unit}',
      themeColor: _pinnedMainGoal!.color,
      isPinned: true,
      onPin: () => setState(() => _pinnedMainGoal = null),
      onEdit: () => _showSnackBar('เปิดหน้าแก้ไข'),
      onDelete: () => setState(() {
        _customRoutines.removeWhere((r) => r.id == _pinnedMainGoal!.id);
        _pinnedMainGoal = null;
      }),
    );
  }

  Widget _buildDefaultMainGoalCard() {
    return _buildBaseMainGoalCard(
      title: 'วิ่งเก็บระยะทาง 15 กม.',
      subtitle: 'โซน 2 รักษาเพซ 6:30 • สะสมเดือนนี้แล้ว 210/500 กม.',
      iconData: Icons.directions_run,
      progress: 'เริ่มวิ่ง',
      themeColor: darkGreen,
      isPinned: true,
      onPin: () => _showSnackBar('เลิกปักหมุดวิ่ง'),
      onEdit: () => _showSnackBar('แก้ไขวิ่ง'),
      onDelete: () => _showSnackBar('ลบเป้าหมายวิ่ง'),
    );
  }

  Widget _buildBaseMainGoalCard({
    required String title,
    required String subtitle,
    required IconData iconData,
    required String progress,
    required Color themeColor,
    required bool isPinned,
    required VoidCallback onPin,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardGreenBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryGreen.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 12, right: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: darkGreen, borderRadius: BorderRadius.circular(12)),
                  child: const Text('🚩 กิจวัตรจากเป้าหมายหลัก', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                _buildThreeDotsMenu(onPin: onPin, onEdit: onEdit, onDelete: onDelete, isPinned: isPinned),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: themeColor.withAlpha(30), shape: BoxShape.circle),
                      child: Icon(iconData, color: themeColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: Text(progress, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.checklist, size: 16, color: darkGreen),
                    const SizedBox(width: 8),
                    Text('เช็กลิสต์ย่อยประจำรอบวันนี้', style: TextStyle(fontSize: 12, color: darkGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildChecklistItem('วอร์มอัพ 10 นาที', _isWarmupChecked, (val) => setState(() => _isWarmupChecked = val!)),
                const SizedBox(height: 8),
                _buildChecklistItem('ยืดเหยียดผ่อนคลาย', _isCooldownChecked, (val) => setState(() => _isCooldownChecked = val!)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool isChecked, Function(bool?) onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: isChecked ? primaryGreen.withAlpha(50) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isChecked ? primaryGreen : Colors.transparent),
      ),
      child: CheckboxListTile(
        value: isChecked,
        onChanged: onChanged,
        title: Text(title, style: TextStyle(fontSize: 14, color: isChecked ? darkGreen : Colors.black87, fontWeight: isChecked ? FontWeight.bold : FontWeight.normal)),
        activeColor: darkGreen,
        checkColor: Colors.white,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        dense: true,
      ),
    );
  }

  Widget _buildDailyRoutinesHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('กิจวัตรประจำวัน (Daily\nRoutines)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.2)),
        Text('3 ช่วง\nเวลา', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTimeBlockHeader(String title, String timeRange) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1C2819))),
          Text(timeRange, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildCustomRoutineCard(RoutineItem item) {
    final bool isPinned = _pinnedMainGoal?.id == item.id;
    return _buildRoutineCard(
      icon: item.iconData,
      iconBg: item.color.withAlpha(30),
      iconColor: item.color,
      title: item.title,
      badgeText: '${item.progressPercent}%',
      badgeColor: item.color.withAlpha(30),
      badgeTextColor: item.color,
      subtitle: 'เป้าหมาย: ${item.targetValue.toInt()} ${item.unit} (${item.notificationTime})',
      actionWidget: IconButton(
        icon: Icon(Icons.add_circle, color: item.color),
        onPressed: () => setState(() => item.currentValue = (item.currentValue + 1).clamp(0, item.targetValue)),
      ),
      progressText: '${item.currentValue.toInt()} / ${item.targetValue.toInt()} ${item.unit} (${item.progressPercent}%)',
      progressValue: item.progressRatio,
      progressColor: item.color,
      onPin: () => setState(() => isPinned ? _pinnedMainGoal = null : _pinnedMainGoal = item),
      onEdit: () => _showSnackBar('แก้ไข ${item.title}'),
      onDelete: () => setState(() {
        _customRoutines.removeWhere((r) => r.id == item.id);
        if (isPinned) _pinnedMainGoal = null;
      }),
      isPinned: isPinned,
    );
  }

  Widget _buildRoutineCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String badgeText,
    Color badgeColor = const Color(0xFFE3F2FD),
    Color badgeTextColor = const Color(0xFF1976D2),
    required String subtitle,
    required Widget actionWidget,
    required String progressText,
    required double progressValue,
    required Color progressColor,
    required VoidCallback onPin,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    bool isPinned = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
                          child: Text(badgeText, style: TextStyle(color: badgeTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Row(
                children: [
                  actionWidget,
                  _buildThreeDotsMenu(onPin: onPin, onEdit: onEdit, onDelete: onDelete, isPinned: isPinned),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ความคืบหน้า', style: TextStyle(fontSize: 12, color: Colors.black54)),
              Text(progressText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}