// services/subscription_service.dart
import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/user_storage.dart';

class SubscriptionService {
  final HttpService _httpService = HttpService();

  // 获取订阅链接的方法（从缓存的用户信息获取）
  Future<String?> getSubscriptionLink(String accessToken) async {
    if (kDebugMode) {
      print('[SubscriptionService] 开始获取订阅链接...');
    }

    // 从缓存的用户信息获取订阅链接
    final cachedUserInfo = await getUserInfo();
    if (cachedUserInfo != null) {
      // 尝试多个可能的字段名
      String? subscribeUrl = cachedUserInfo['subscribeUrl'] as String?;
      subscribeUrl ??= cachedUserInfo['subscribe_url'] as String?;

      if (kDebugMode) {
        print('[SubscriptionService] 从缓存获取订阅URL: $subscribeUrl');
      }

      if (subscribeUrl != null && subscribeUrl.isNotEmpty) {
        return subscribeUrl;
      }
    }

    // 如果缓存中没有，抛出异常
    throw Exception("No subscription link found in cached user info");
  }

  // 重置订阅链接的方法
  Future<String?> resetSubscriptionLink(String accessToken) async {
    if (kDebugMode) {
      print('[SubscriptionService] 开始重置订阅链接...');
    }

    final result = await _httpService.getRequest(
      "/hjapi/appApi/resetSecurity",
      headers: {
        'Authorization': accessToken,
      },
    );

    if (kDebugMode) {
      print('[SubscriptionService] 重置API返回结果: $result');
    }

    if (result.containsKey("data")) {
      final data = result["data"];
      if (data is String) {
        return data;
      }
      // 如果data是Map，尝试从中获取URL
      if (data is Map<String, dynamic>) {
        String? subscribeUrl = data['subscribeUrl'] as String?;
        subscribeUrl ??= data['subscribe_url'] as String?;
        return subscribeUrl;
      }
    }
    throw Exception("Failed to reset subscription link");
  }
}
