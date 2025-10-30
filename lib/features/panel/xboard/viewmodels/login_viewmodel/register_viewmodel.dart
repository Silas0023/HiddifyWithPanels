// viewmodels/register_viewmodel.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';

class RegisterViewModel extends ChangeNotifier {
  final AuthService _authService;
  // 添加 FormKey
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isCountingDown = false;
  bool get isCountingDown => _isCountingDown;

  bool _isSendingCode = false;
  bool get isSendingCode => _isSendingCode;

  int _countdownTime = 60;
  int get countdownTime => _countdownTime;

  bool _obscurePassword = true;
  bool get obscurePassword => _obscurePassword;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController inviteCodeController = TextEditingController();
  final TextEditingController emailCodeController = TextEditingController();

  RegisterViewModel({required AuthService authService})
      : _authService = authService;

  Future<void> sendVerificationCode(BuildContext context) async {
    final email = emailController.text.trim();

    _isSendingCode = true;
    notifyListeners();

    try {
      final response = await _authService.sendVerificationCode(email);

      _isSendingCode = false;
      notifyListeners();

      // 检查响应状态码是否为 200（成功）
      if (response["status"] == 200) {
        _showSnackbar(context, "验证码已发送到 $email");

        // 只有在发送成功后才开始倒计时
        _isCountingDown = true;
        _countdownTime = 60;
        notifyListeners();

        // 倒计时逻辑
        while (_countdownTime > 0) {
          await Future.delayed(const Duration(seconds: 1));
          _countdownTime--;
          notifyListeners();
        }

        _isCountingDown = false;
        notifyListeners();
      } else {
        // 发送失败，显示错误消息
        _showSnackbar(context, response["message"]?.toString() ?? "发送失败");
      }
    } catch (e) {
      _isSendingCode = false;
      notifyListeners();
      _showSnackbar(context, "发送失败: $e");
    }
  }

  Future<void> register(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final inviteCode = inviteCodeController.text.trim();
    final emailCode = emailCodeController.text.trim();

    try {
      final result = await _authService.register(
        email,
        password,
        inviteCode,
        emailCode,
      );

      if (result["status"] == "success") {
        _showSnackbar(context, "Registration successful");
        if (context.mounted) {
          context.go('/login');
        }
      } else {
        _showSnackbar(context, result["message"].toString());
      }
    } catch (e) {
      _showSnackbar(context, "Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void _showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    inviteCodeController.dispose();
    emailCodeController.dispose();
    super.dispose();
  }
}
