part of 'edit_profile_dialog.dart';

extension EditProfileDialogLabels on _EditProfileDialogState {
  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF6F7A72),
        letterSpacing: 0.2,
      ),
    );
  }
}
