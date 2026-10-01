import 'package:flutter/material.dart';
import 'package:healthymate/core/database/app_database.dart';
import 'package:healthymate/core/services/api_service.dart';
import 'package:healthymate/core/services/auth_service.dart';
import 'package:healthymate/core/services/biometric_apple_auth_service.dart';
import 'package:healthymate/core/services/sync_service.dart';
import 'package:healthymate/shared/theme/app_theme.dart';
import 'package:healthymate/features/health_calculator/models/user_model.dart';
import 'package:healthymate/features/register/pages/register_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:healthymate/core/services/supabase_service.dart';
import '../widgets/index.dart';

part 'login_page_google.dart';
part 'login_page_form_actions.dart';
part 'login_page_other_auth.dart';
part 'login_page_content.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onLoginSuccess;

  const LoginPage({super.key, this.onClose, this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -12.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -12.0, end: 12.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 12.0, end: -8.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 8.0, end: -4.0), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );
  }

  void _triggerShake() {
    _shakeController.forward(from: 0.0);
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    _triggerShake();
  }

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  int _failedAttempts = 0;
  DateTime? _lockoutUntil;

  @override
  void dispose() {
    _shakeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => this._buildLoginPage(context);
}
