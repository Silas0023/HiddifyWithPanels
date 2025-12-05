// services/user_service.dart
import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/user_storage.dart';

class UserService {
  final HttpService _httpService = HttpService();

  // 获取用户信息（使用缓存的用户ID调用刷新接口）
  Future<UserInfo?> fetchUserInfo(String accessToken) async {
    try {
      // 先尝试从缓存获取用户ID
      final userId = await getUserId();
      if (userId != null && userId > 0) {
        if (kDebugMode) {
          print('[UserService] 使用缓存的用户ID: $userId');
        }
        return await refreshUserInfo(accessToken, userId);
      }

      // 如果没有缓存的用户ID，尝试从缓存的用户信息中获取
      final cachedUserInfo = await getUserInfo();
      if (cachedUserInfo != null) {
        final cachedUserId = cachedUserInfo['id'] as int?;
        if (cachedUserId != null && cachedUserId > 0) {
          if (kDebugMode) {
            print('[UserService] 从缓存用户信息获取ID: $cachedUserId');
          }
          return await refreshUserInfo(accessToken, cachedUserId);
        }
        // 返回缓存的用户信息
        if (kDebugMode) {
          print('[UserService] 使用缓存的用户信息');
        }
        return UserInfo.fromJson(cachedUserInfo);
      }

      throw Exception("No user ID found. Please login again.");
    } catch (e) {
      if (kDebugMode) {
        print('[UserService] 获取用户信息失败: $e');
      }
      rethrow;
    }
  }

  // 刷新用户信息
  Future<UserInfo?> refreshUserInfo(String accessToken, int userId) async {
    try {
      final result = await _httpService.getRequest(
        "/hjapi/appApi/refresh/$userId",
        headers: {'Authorization': accessToken},
      );

      if (result.containsKey("data")) {
        final data = result["data"] as Map<String, dynamic>;
        if (kDebugMode) {
          print('[UserService] 刷新用户信息: $data');
        }
        // 更新缓存的用户信息
        await storeUserInfo(data);
        return UserInfo.fromJson(data);
      }
      throw Exception("Failed to refresh user info");
    } catch (e) {
      if (kDebugMode) {
        print('[UserService] 刷新用户信息失败: $e');
      }
      rethrow;
    }
  }

  Future<bool> validateToken(String token) async {
    try {
      // 使用缓存的用户ID验证token
      final userId = await getUserId();
      if (userId == null || userId <= 0) {
        return false;
      }
      final response = await _httpService.getRequest(
        "/hjapi/appApi/refresh/$userId",
        headers: {'Authorization': token},
      );
      // 如果请求成功返回且有data字段，说明token有效
      return response.containsKey('data');
    } catch (_) {
      return false;
    }
  }

  Future<String?> getSubscriptionLink(String accessToken) async {
    // 从缓存获取订阅链接（尝试多个可能的字段名）
    final cachedUserInfo = await getUserInfo();
    if (cachedUserInfo != null) {
      String? subscribeUrl = cachedUserInfo['subscribeUrl'] as String?;
      subscribeUrl ??= cachedUserInfo['subscribe_url'] as String?;
      if (subscribeUrl != null && subscribeUrl.isNotEmpty) {
        return subscribeUrl;
      }
    }
    // 如果缓存中没有，尝试刷新获取
    final userId = await getUserId();
    if (userId != null && userId > 0) {
      final result = await _httpService.getRequest(
        "/hjapi/appApi/refresh/$userId",
        headers: {'Authorization': accessToken},
      );
      final data = result["data"] as Map<String, dynamic>?;
      if (data != null) {
        return (data['subscribeUrl'] as String?) ?? (data['subscribe_url'] as String?);
      }
    }
    return null;
  }

  Future<String?> resetSubscriptionLink(String accessToken) async {
    final result = await _httpService.getRequest(
      "/hjapi/appApi/resetSecurity",
      headers: {'Authorization': accessToken},
    );
    return result["data"] as String?;
  }
}
