part of 'edit_profile_dialog.dart';

extension EditProfileDialogSave on _EditProfileDialogState {
  Future<void> _handleSave(BuildContext context) async {
    final fName = _firstCtrl.text.trim();
    final lName = _lastCtrl.text.trim();

    if (fName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกชื่อ'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final age = int.tryParse(_ageCtrl.text) ?? widget.currentUser?.nAge ?? 0;
    if (age < 0 || age > 130) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('อายุต้องอยู่ระหว่าง 1 - 130 ปี'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final height =
        double.tryParse(_heightCtrl.text) ?? widget.currentUser?.nHeight ?? 0.0;
    if (height < 0.0 || height > 280.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ส่วนสูงต้องอยู่ระหว่าง 30 - 280 ซม.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final weight =
        double.tryParse(_weightCtrl.text) ?? widget.currentUser?.nWeight ?? 0.0;
    if (weight < 0.0 || weight > 500.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('น้ำหนักต้องอยู่ระหว่าง 10 - 500 กก.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await widget.onSave(
      firstName: fName,
      lastName: lName,
      gender: _currentGender,
      age: age,
      height: height,
      weight: weight,
    );
    if (context.mounted) Navigator.pop(context);
  }
}
