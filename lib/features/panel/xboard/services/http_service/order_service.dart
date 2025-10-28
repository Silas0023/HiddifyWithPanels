// services/order_service.dart
import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/models/order_model.dart';

import 'package:hiddify/features/panel/xboard/services/http_service/http_service.dart';

class OrderService {
  final HttpService _httpService = HttpService();

  Future<List<Order>> fetchUserOrders(String accessToken) async {
    try {
      final result = await _httpService.getRequest(
        "/api/v1/user/order/fetch",
        headers: {'Authorization': accessToken},
      );

      if (kDebugMode) {
        print('fetchUserOrders: Full response: $result');
        print('fetchUserOrders: Status: ${result["status"] ?? "no status field"}');
        print('fetchUserOrders: Data type: ${result["data"]?.runtimeType ?? "no data field"}');
      }

      // Check for different response formats
      if (result.containsKey("data")) {
        final data = result["data"];

        // If data is null, return empty list
        if (data == null) {
          if (kDebugMode) {
            print('fetchUserOrders: data is null, returning empty list');
          }
          return [];
        }

        // If data is a List, parse it
        if (data is List) {
          if (kDebugMode) {
            print('fetchUserOrders: Found ${data.length} orders');
          }
          return data
              .map((json) => Order.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }

      // If we get here, the response format is unexpected
      if (kDebugMode) {
        print('fetchUserOrders: Unexpected response format');
        print('fetchUserOrders: Response keys: ${result.keys}');
      }

      // Return empty list instead of throwing exception for unexpected format
      return [];
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('fetchUserOrders error: $e');
        print('fetchUserOrders stack trace: $stackTrace');
      }
      // Return empty list instead of rethrowing
      return [];
    }
  }

  Future<Map<String, dynamic>> getOrderDetails(
      String tradeNo,
      String accessToken,
  ) async {
    return await _httpService.getRequest(
      "/api/v1/user/order/detail?trade_no=$tradeNo",
      headers: {'Authorization': accessToken},
    );
  }

  Future<Map<String, dynamic>> cancelOrder(
      String tradeNo,
      String accessToken,
  ) async {
    return await _httpService.postFormRequest(
      "/api/v1/user/order/cancel",
      {"trade_no": tradeNo},
      headers: {'Authorization': accessToken},
    );
  }

  Future<Map<String, dynamic>> createOrder(
      String accessToken,
      int planId,
      String period,
  ) async {
    return await _httpService.postFormRequest(
      "/api/v1/user/order/save",
      {
        "plan_id": planId.toString(),
        "period": period,
      },
      headers: {'Authorization': accessToken},
    );
  }
}
