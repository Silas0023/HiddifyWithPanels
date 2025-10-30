// viewmodels/forget_password_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';

class ForgetPasswordViewModel extends ChangeNotifier {
  final AuthService _authService;

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
  final TextEditingController emailCodeController = TextEditingController();

  ForgetPasswordViewModel({required AuthService authService})
      : _authService = authService;

  Future<void> sendVerificationCode() async {
    final email = emailController.text.trim();

    _isSendingCode = true;
    notifyListeners();

    try {
      final response = await _authService.sendVerificationCode(email, tag: 'forget');

      _isSendingCode = false;
      notifyListeners();

      // 检查响应状态码是否为 200（成功）
      if (response["status"] == 200) {
        // 只有在发送成功后才开始倒计时
        _isCountingDown = true;
        _countdownTime = 60;
        notifyListeners();

        while (_countdownTime > 0) {
          await Future.delayed(const Duration(seconds: 1));
          _countdownTime--;
          notifyListeners();
        }

        _isCountingDown = false;
        notifyListeners();
      } else {
        // 发送失败，显示错误信息
        if (kDebugMode) {
          print("发送验证码失败: ${response["message"]}");
        }
      }
    } catch (e) {
      _isSendingCode = false;
      notifyListeners();
      // 请求异常时，记录错误
      if (kDebugMode) {
        print("发送验证码异常: $e");
      }
    }
  }


  Future<void> resetPassword(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final emailCode = emailCodeController.text.trim();

    try {
      await _authService.resetPassword(email, password, emailCode);
      if (context.mounted) {
        context.go('/login');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailCodeController.dispose();
    super.dispose();
  }
}
