// services/auth_service.dart
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class AuthService {
  final HttpService _httpService = HttpService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    return await _httpService.postRequest(
      "/api/mobile/auth/email/login",
      {"email": email, "password": password},
      requiresHeaders: false,
    );
  }

  Future<Map<String, dynamic>> register(String email, String password, String inviteCode, String emailCode) async {
    return await _httpService.postRequest(
      "/api/v1/passport/auth/register",
      {
        "email": email,
        "password": password,
        "invite_code": inviteCode,
        "email_code": emailCode,
      },
    );
  }

  Future<Map<String, dynamic>> sendVerificationCode(String email, {String tag = 'register'}) async {
    return await _httpService.postFormRequest(
      "/apiv2/clickPass/sendEmailByHaHa",
      {
        'email': email,
        'tag': tag,
      },
    );
  }

  // 发送短信验证码
  Future<Map<String, dynamic>> sendSmsCode(String phone) async {
    return await _httpService.getRequest(
      "/hjapi/appApi/sendCheckCode?phone=$phone",
    );
  }

  // 手机号验证码登录
  Future<Map<String, dynamic>> loginWithPhone(String phone, String code) async {
    return await _httpService.postRequest(
      "/hjapi/appApi/login",
      {
        "phoneNumber": phone,
        "smsCode": code,
      },
      requiresHeaders: false,
    );
  }

  // 邮箱密码登录
  Future<Map<String, dynamic>> loginWithEmail(String email, String password) async {
    return await _httpService.postFormRequest(
      "/apiv2/clickPass/emailLogin",
      {
        "email": email,
        "password": password,
      },
    );
  }

  Future<Map<String, dynamic>> resetPassword(String email, String password, String emailCode) async {
    return await _httpService.postRequest(
      "/api/v1/passport/auth/forget",
      {
        "email": email,
        "password": password,
        "email_code": emailCode,
      },
    );
  }
}
