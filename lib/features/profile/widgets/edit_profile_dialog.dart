import 'package:flutter/material.dart';
import 'package:healthymate/core/services/theme_service.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';

part 'edit_profile_dialog_labels.dart';
part 'edit_profile_dialog_fields.dart';
part 'edit_profile_dialog_gender.dart';
part 'edit_profile_dialog_save.dart';
part 'edit_profile_dialog_content.dart';
part 'edit_profile_dialog_header.dart';

class EditProfileDialog extends StatefulWidget {
  final TbUser? currentUser;
  final Future<void> Function({
    required String firstName,
    required String lastName,
    required String gender,
    required int age,
    required double height,
    required double weight,
  })
  onSave;

  const EditProfileDialog({
    super.key,
    required this.currentUser,
    required this.onSave,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _firstCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late String _currentGender;

  @override
  void initState() {
    super.initState();
    final user = widget.currentUser;
    _firstCtrl = TextEditingController(text: user?.sFirstName ?? '');
    _lastCtrl = TextEditingController(text: user?.sLastName ?? '');
    _ageCtrl = TextEditingController(
      text: (user?.nAge != null && user!.nAge! > 0) ? user.nAge.toString() : '',
    );
    _heightCtrl = TextEditingController(
      text: (user?.nHeight != null && user!.nHeight! > 0)
          ? user.nHeight!.toStringAsFixed(0)
          : '',
    );
    _weightCtrl = TextEditingController(
      text: (user?.nWeight != null && user!.nWeight! > 0)
          ? user.nWeight!.toStringAsFixed(1)
          : '',
    );
    _currentGender = (user?.sGender != null && user!.sGender!.isNotEmpty)
        ? user.sGender!
        : 'male';
  }

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => this._buildEditProfileDialog(context);
}
