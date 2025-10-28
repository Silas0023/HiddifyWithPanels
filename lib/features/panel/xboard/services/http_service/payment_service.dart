// services/payment_service.dart
import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class PaymentService {
  final HttpService _httpService = HttpService();

  Future<Map<String, dynamic>> submitOrder(
      String tradeNo,
      String method,
      String accessToken,
  ) async {
    return await _httpService.postFormRequest(
      "/api/v1/user/order/checkout",
      {"trade_no": tradeNo, "method": method},
      headers: {'Authorization': accessToken},
    );
  }

  Future<List<dynamic>> getPaymentMethods(String accessToken) async {
    try {
      final response = await _httpService.getRequest(
        "/api/v1/user/order/getPaymentMethod",
        headers: {'Authorization': accessToken},
      );

      if (kDebugMode) {
        print('getPaymentMethods response: $response');
      }

      // 检查 data 字段
      if (!response.containsKey('data')) {
        if (kDebugMode) {
          print('getPaymentMethods: response does not contain data field');
        }
        return [];
      }

      final data = response['data'];
      if (data == null) {
        if (kDebugMode) {
          print('getPaymentMethods: data is null');
        }
        return [];
      }

      if (data is! List) {
        if (kDebugMode) {
          print('getPaymentMethods: data is not a List, type: ${data.runtimeType}');
        }
        return [];
      }

      if (kDebugMode) {
        print('getPaymentMethods: found ${data.length} payment methods');
      }
      return data.cast<dynamic>();
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('getPaymentMethods error: $e');
        print('Stack trace: $stackTrace');
      }
      return [];
    }
  }
}
