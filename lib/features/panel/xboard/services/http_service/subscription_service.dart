// services/subscription_service.dart
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class SubscriptionService {
  final HttpService _httpService = HttpService();

  // 获取订阅链接的方法
  Future<String?> getSubscriptionLink(String accessToken) async {
    print('[SubscriptionService] 开始获取订阅链接...');
    final result = await _httpService.getRequest(
      "/api/v1/user/getSubscribe",
      headers: {
        'Authorization': accessToken,
      },
    );

    print('[SubscriptionService] API返回结果: $result');

    if (result.containsKey("data")) {
      final data = result["data"];
      if (data is Map<String, dynamic> && data.containsKey("subscribe_url")) {
        final subscribeUrl = data["subscribe_url"] as String?;
        print('[SubscriptionService] 原始订阅URL: $subscribeUrl');
        if (subscribeUrl != null) {
          // 在订阅地址后添加 &flag=rocket 参数
          final finalUrl = subscribeUrl.contains('?')
              ? '$subscribeUrl&flag=rocket' // 如果已有参数，用 & 连接
              : '$subscribeUrl?flag=rocket'; // 如果没有参数，用 ? 连接
          print('[SubscriptionService] 添加flag后的最终URL: $finalUrl');
          return finalUrl;
        }

        return subscribeUrl;
      }
    }

    // 返回 null 或抛出异常，如果数据结构不匹配
    throw Exception("Failed to retrieve subscription link");
  }

  // 重置订阅链接的方法
  Future<String?> resetSubscriptionLink(String accessToken) async {
    print('[SubscriptionService] 开始重置订阅链接...');
    final result = await _httpService.getRequest(
      "/api/v1/user/resetSecurity",
      headers: {
        'Authorization': accessToken,
      },
    );
    print('[SubscriptionService] 重置API返回结果: $result');
    if (result.containsKey("data")) {
      final data = result["data"];
      if (data is String) {
        print('[SubscriptionService] 原始重置订阅URL: $data');
        // 在订阅地址后添加 &flag=rocket 参数
        final finalUrl = data.contains('?')
            ? '$data&flag=rocket' // 如果已有参数，用 & 连接
            : '$data?flag=rocket'; // 如果没有参数，用 ? 连接
        print('[SubscriptionService] 添加flag后的最终重置URL: $finalUrl');
        return finalUrl;
      }
    }
    throw Exception("Failed to reset subscription link");
  }
}
