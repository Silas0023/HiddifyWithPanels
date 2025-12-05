import 'package:flutter/material.dart';

import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/order_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/payment_service.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/plan_service.dart';
import 'package:hiddify/features/panel/xboard/services/subscription.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

class PurchaseService {
  Future<List<Plan>> fetchPlanData() async {
    final accessToken = await getToken();
    if (accessToken == null) {
      print("No access token found.");
      return [];
    }

    return await PlanService().fetchPlanData(accessToken);
  }

  Future<Map<String, List<Plan>>> fetchPlanDataGrouped() async {
    final accessToken = await getToken();
    if (accessToken == null) {
      print("No access token found.");
      return {};
    }

    return await PlanService().fetchPlanDataGrouped(accessToken);
  }

  Future<void> addSubscription(
    BuildContext context,
    String accessToken,
    WidgetRef ref,
    Function showSnackbar,
  ) async {
    Subscription.updateSubscription(context, ref);
  }

  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();

  /// 创建订单
  /// [userId] 用户ID
  /// [planValue] 套餐的appleValue
  /// [payType] 支付类型: 1=支付宝, 2=微信支付
  Future<Map<String, dynamic>?> createOrder(
      int userId, String planValue, int payType, String accessToken) async {
    return await _orderService.createOrder(accessToken, userId, planValue, payType);
  }

  Future<List<dynamic>> getPaymentMethods(String accessToken) async {
    return await _paymentService.getPaymentMethods(accessToken);
  }

  Future<Map<String, dynamic>> submitOrder(
      String tradeNo, String method, String accessToken) async {
    return await _paymentService.submitOrder(tradeNo, method, accessToken);
  }
}
