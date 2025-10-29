// viewmodels/login_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/services/auth_provider.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/auth_service.dart';
import 'package:hiddify/features/panel/xboard/services/subscription.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRememberMe = false;
  bool get isRememberMe => _isRememberMe;

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginViewModel({required AuthService authService})
      : _authService = authService {
    // 初始化时不自动加载账号密码
    _loadRememberMeState();
  }

  // 只加载"记住我"的状态
  Future<void> _loadRememberMeState() async {
    final prefs = await SharedPreferences.getInstance();
    _isRememberMe = prefs.getBool('is_remember_me') ?? false;
    notifyListeners();
  }

  // 加载邮箱登录的保存账号密码（仅在切换到邮箱登录时调用）
  Future<void> loadEmailCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isRememberMe) {
      usernameController.text = prefs.getString('saved_email') ?? '';
      passwordController.text = prefs.getString('saved_email_password') ?? '';
    }
    notifyListeners();
  }

  // 保存邮箱登录的账号密码
  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_isRememberMe) {
      await prefs.setString('saved_email', usernameController.text);
      await prefs.setString('saved_email_password', passwordController.text);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_email_password');
    }
    await prefs.setBool('is_remember_me', _isRememberMe);
  }

  void toggleRememberMe(bool value) {
    _isRememberMe = value;
    notifyListeners();
  }

  Future<void> login(
    String email,
    String password,
    BuildContext context,
    WidgetRef ref,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);

      String? authData;
      String? token;

      // 查找 authData 和 token 的方法
      void findAuthData(Map<String, dynamic> json) {
        json.forEach((key, value) {
          if (key == 'auth_data' && value is String) {
            authData = value;
          }
          if (key == 'token' && value is String) {
            token = value;
          }
          if (value is Map<String, dynamic>) {
            findAuthData(value);
          }
        });
      }

      findAuthData(result);

      // 如果找到了 token，使用 token 作为认证数据
      // 如果同时有 auth_data 和 token，优先使用 auth_data
      if (authData != null || token != null) {
        final authToken = authData ?? token!;
        await storeToken(authToken);
        await _saveCredentials();

        // 使用封装好的 Subscription 来更新订阅
        // ignore: use_build_context_synchronously
        await Subscription.updateSubscription(context, ref);
        // 更新 authProvider 状态为已登录
        ref.read(authProvider.notifier).state = true;
      } else {
        throw Exception("Invalid authentication data.");
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 发送手机验证码
  Future<Map<String, dynamic>> sendSmsCode(String phone) async {
    return await _authService.sendSmsCode(phone);
  }

  // 手机号验证码登录
  Future<void> loginWithPhone(
    String phone,
    String code,
    BuildContext context,
    WidgetRef ref,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.loginWithPhone(phone, code);

      String? authData;
      String? token;

      // 查找 authData 和 token 的方法
      void findAuthData(Map<String, dynamic> json) {
        json.forEach((key, value) {
          if (key == 'auth_data' && value is String) {
            authData = value;
          }
          if (key == 'token' && value is String) {
            token = value;
          }
          if (value is Map<String, dynamic>) {
            findAuthData(value);
          }
        });
      }

      findAuthData(result);

      // 如果找到了 token，使用 token 作为认证数据
      // 如果同时有 auth_data 和 token，优先使用 auth_data
      if (authData != null || token != null) {
        final authToken = authData ?? token!;
        await storeToken(authToken);

        // 使用封装好的 Subscription 来更新订阅
        // ignore: use_build_context_synchronously
        await Subscription.updateSubscription(context, ref);
        // 更新 authProvider 状态为已登录
        ref.read(authProvider.notifier).state = true;
      } else {
        throw Exception("Invalid authentication data.");
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 邮箱密码登录
  Future<void> loginWithEmail(
    String email,
    String password,
    BuildContext context,
    WidgetRef ref,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _authService.loginWithEmail(email, password);

      String? authData;
      String? token;

      // 查找 authData 和 token 的方法
      void findAuthData(Map<String, dynamic> json) {
        json.forEach((key, value) {
          if (key == 'auth_data' && value is String) {
            authData = value;
          }
          if (key == 'token' && value is String) {
            token = value;
          }
          if (value is Map<String, dynamic>) {
            findAuthData(value);
          }
        });
      }

      findAuthData(result);

      // 如果找到了 token，使用 token 作为认证数据
      // 如果同时有 auth_data 和 token，优先使用 auth_data
      if (authData != null || token != null) {
        final authToken = authData ?? token!;
        await storeToken(authToken);
        await _saveCredentials();

        // 使用封装好的 Subscription 来更新订阅
        // ignore: use_build_context_synchronously
        await Subscription.updateSubscription(context, ref);
        // 更新 authProvider 状态为已登录
        ref.read(authProvider.notifier).state = true;
      } else {
        throw Exception("Invalid authentication data.");
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
