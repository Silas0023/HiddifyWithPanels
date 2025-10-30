// services/user_service.dart
import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class UserService {
  final HttpService _httpService = HttpService();

  Future<UserInfo?> fetchUserInfo(String accessToken) async {
    try {
      // 同时获取用户信息和订阅信息（包含流量数据）
      final infoResult = await _httpService.getRequest(
        "/api/v1/user/info",
        headers: {'Authorization': accessToken},
      );

      final subscribeResult = await _httpService.getRequest(
        "/api/v1/user/getSubscribe",
        headers: {'Authorization': accessToken},
      );

      if (infoResult.containsKey("data")) {
        final data = infoResult["data"] as Map<String, dynamic>;

        // 从 getSubscribe 获取流量数据并合并到用户信息中
        if (subscribeResult.containsKey("data")) {
          final subscribeData = subscribeResult["data"] as Map<String, dynamic>;

          // 合并流量数据
          data['u'] = subscribeData['u'];
          data['d'] = subscribeData['d'];
          data['transfer_enable'] = subscribeData['transfer_enable'];

          if (kDebugMode) {
            print('[UserService] 合并流量数据: u=${data['u']}, d=${data['d']}, transfer_enable=${data['transfer_enable']}');
          }
        }

        return UserInfo.fromJson(data);
      }
      throw Exception("Failed to retrieve user info");
    } catch (e) {
      if (kDebugMode) {
        print('[UserService] 获取用户信息失败: $e');
      }
      rethrow;
    }
  }

  Future<bool> validateToken(String token) async {
    try {
      final response = await _httpService.getRequest(
        "/api/v1/user/getSubscribe",
        headers: {'Authorization': token},
      );
      // 如果请求成功返回且有data字段，说明token有效
      return response.containsKey('data');
    } catch (_) {
      return false;
    }
  }

  Future<String?> getSubscriptionLink(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/getSubscribe",
      headers: {'Authorization': accessToken},
    );
    // ignore: avoid_dynamic_calls
    return result["data"]["subscribe_url"] as String?;
  }

  Future<String?> resetSubscriptionLink(String accessToken) async {
    final result = await _httpService.getRequest(
      "/api/v1/user/resetSecurity",
      headers: {'Authorization': accessToken},
    );
    return result["data"] as String?;
  }
}
