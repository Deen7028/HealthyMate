import 'package:flutter/material.dart';

// วิดเจ็ตปุ่มลอยควบคุมแผนที่ (Map Floating Buttons Widget)
// แสดงปุ่มเลือกเลเยอร์ประเภทแผนที่ (Layers) และปุ่มปรับมุมมองกลับมายังตำแหน่งปัจจุบัน (My Location)
class MapFloatingButtons extends StatelessWidget {
  final String? mapTypeBadgeText;
  final VoidCallback onLayersTap;
  final VoidCallback onMyLocationTap;

  const MapFloatingButtons({
    super.key,
    this.mapTypeBadgeText,
    required this.onLayersTap,
    required this.onMyLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMapFloatingButton(
          icon: Icons.layers_rounded,
          badgeText: mapTypeBadgeText,
          onTap: onLayersTap,
        ),
        const SizedBox(height: 12),
        _buildMapFloatingButton(
          icon: Icons.my_location_rounded,
          onTap: onMyLocationTap,
        ),
      ],
    );
  }

  Widget _buildMapFloatingButton({
    required IconData icon,
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: const Color(0xFF2E5327), size: 24),
            if (badgeText != null)
              Positioned(
                top: -18,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E5327),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
