import 'package:flutter/material.dart';

class MainGoalCardSetupButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const MainGoalCardSetupButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 46,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.white),
      label: const Text(
        '+ ตั้งเป้าหมายหลัก (Set Main Goal)',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF006432),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
