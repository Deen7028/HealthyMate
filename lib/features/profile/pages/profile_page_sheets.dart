part of 'profile_page.dart';

extension ProfilePageSheets on _ProfilePageState {
  void _showUnitPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return UnitPickerBottomSheet(
          selectedUnit: _controller.selectedUnit,
          onUnitSelected: (unit) async {
            await _controller.saveUserUnitPreference(unit);
          },
        );
      },
    );
  }

  void _showEditProfileDialog() {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => EditProfileDialog(
        currentUser: _controller.currentUser,
        onSave:
            ({
              required String firstName,
              required String lastName,
              required String gender,
              required int age,
              required double height,
              required double weight,
            }) async {
              final isSynced = await _controller.updateProfileInfo(
                firstName: firstName,
                lastName: lastName,
                gender: gender,
                age: age,
                height: height,
                weight: weight,
              );

              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      isSynced
                          ? 'อัปเดตและซิงค์ข้อมูลโปรไฟล์เรียบร้อยแล้ว ☁️'
                          : 'บันทึกข้อมูลในเครื่องเรียบร้อยแล้ว (จะซิงค์เมื่อมีเน็ต)',
                    ),
                    backgroundColor: primaryColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
      ),
    );
  }

  void _showConnectedDevicesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return ConnectedDevicesBottomSheet(
              connectedDevices: _controller.connectedDevices,
              onAddDevice: (providerName) async {
                await _controller.addConnectedDevice(providerName);
                setModalState(() {});
              },
              onToggleDevice: (integrationId, isActive) async {
                await _controller.toggleConnectedDeviceStatus(
                  integrationId,
                  isActive,
                );
                setModalState(() {});
              },
              onDeleteDevice: (integrationId) async {
                await _controller.deleteConnectedDevice(integrationId);
                setModalState(() {});
              },
            );
          },
        );
      },
    );
  }

  void _showPersonalInfoBottomSheet() {
    final user = _controller.currentUser;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return PersonalInfoBottomSheet(
          fullName: user?.sFullName ?? '',
          email: user?.sEmail ?? AuthService.instance.currentUserEmail,
          gender: user?.sGender ?? 'male',
          age: user?.nAge ?? 0,
          height: user?.nHeight ?? 0.0,
          weight: user?.nWeight ?? 0.0,
          onEditTap: this._showEditProfileDialog,
        );
      },
    );
  }
}
