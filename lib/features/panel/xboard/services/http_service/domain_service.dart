// services/domain_service.dart
import 'package:flutter/foundation.dart';

class DomainService {
  // 从返回的 JSON 中挑选一个可以正常访问的域名
  static Future<String> fetchValidDomain() async {
    // 直接返回指定的域名
    const String fixedDomain = 'https://test.23687.xyz';
    if (kDebugMode) {
      print('Using fixed domain: $fixedDomain');
    }
    return fixedDomain;
  }
}
