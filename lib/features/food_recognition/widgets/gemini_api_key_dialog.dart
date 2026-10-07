import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';

part 'gemini_api_key_dialog_save.dart';
part 'gemini_api_key_dialog_content.dart';

class GeminiApiKeyDialog extends StatefulWidget {
  final int userId;
  final String initialKey;
  final ValueChanged<String> onSaved;

  const GeminiApiKeyDialog({
    super.key,
    required this.userId,
    required this.initialKey,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required int userId,
    required String currentKey,
    required ValueChanged<String> onSaved,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => GeminiApiKeyDialog(
        userId: userId,
        initialKey: currentKey,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<GeminiApiKeyDialog> createState() => _GeminiApiKeyDialogState();
}

class _GeminiApiKeyDialogState extends State<GeminiApiKeyDialog> {
  late final TextEditingController _keyCtrl;
  bool _obscureText = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController(text: widget.initialKey);
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildDialog(context);
}
