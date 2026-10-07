import 'package:flutter/material.dart';

class WorkoutShareActions extends StatelessWidget {
  final bool isTransparent;
  final bool isProcessing;
  final String processAction;
  final VoidCallback onToggleTransparent;
  final VoidCallback onSaveToGallery;
  final VoidCallback onExportAndShare;

  const WorkoutShareActions({
    super.key,
    required this.isTransparent,
    required this.isProcessing,
    required this.processAction,
    required this.onToggleTransparent,
    required this.onSaveToGallery,
    required this.onExportAndShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'แชร์ไปยัง',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              TextButton.icon(
                icon: const Icon(Icons.style_rounded,
                    size: 16, color: Color(0xFF2E5327)),
                label: Text(
                  isTransparent ? 'เปลี่ยนเป็นสีพื้น' : 'เปลี่ยนเป็นโปร่งใส',
                  style: const TextStyle(
                    color: Color(0xFF2E5327),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: onToggleTransparent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: (isProcessing && processAction == 'save')
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.download_rounded, size: 22),
              label: Text(
                (isProcessing && processAction == 'save')
                    ? 'กำลังบันทึกรูปลงเครื่อง...'
                    : 'บันทึกรูปลงเครื่อง (Gallery)',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E5327),
                foregroundColor: Colors.white,
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: isProcessing ? null : onSaveToGallery,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: (isProcessing && processAction == 'share')
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Color(0xFF2E5327),
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.share_rounded,
                      size: 20, color: Color(0xFF2E5327)),
              label: Text(
                (isProcessing && processAction == 'share')
                    ? 'กำลังเตรียมแชร์...'
                    : 'แชร์ไปยัง Story หรือแอปอื่นๆ',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2E5327),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2E5327), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: isProcessing ? null : onExportAndShare,
            ),
          ),
        ],
      ),
    );
  }
}
