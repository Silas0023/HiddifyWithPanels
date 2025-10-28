import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/order_service.dart';

class MonitorPayStatus {
  Timer? _pollingTimer;

  // 监控订单状态，轮询20分钟后停止
  Future<void> monitorOrderStatus(
    String tradeNo,
    String accessToken,
    Function(bool) onPaymentStatusChanged,
  ) async {
    bool isPaymentComplete = false;
    const int maxPollingDuration = 20 * 60; // 20 minutes in seconds
    int elapsedTime = 0;

    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (isPaymentComplete || elapsedTime >= maxPollingDuration) {
        timer.cancel(); // 支付完成或超时后停止轮询
        return;
      }

      elapsedTime += 10; // 每次轮询增加10秒

      try {
        final orderDetails = await getOrderDetails(tradeNo, accessToken);
        if (kDebugMode) {
          print('Order details: $orderDetails');
        }
        final orderData = orderDetails['data'];

        // 检查订单是否被取消
        if (orderData['status'] is int && orderData['status'] == 2) {
          isPaymentComplete = true; // 停止轮询
          timer.cancel();
          if (kDebugMode) {
            print('订单已取消');
          }
          return;
        }

        // 检查订单是否已支付
        if (orderData['status'] is int && orderData['status'] == 0) {
          if (kDebugMode) {
            print('订单未支付');
          }
          onPaymentStatusChanged(false); // 通知支付未完成
        } else if (orderData['status'] is int && orderData['status'] == 3) {
          isPaymentComplete = true; // 标记支付完成
          if (kDebugMode) {
            print('订单支付成功');
          }
          onPaymentStatusChanged(true); // 通知支付完成
          timer.cancel(); // 停止轮询
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error while checking order status: $e");
        }
      }
    });
  }

  // 取消轮询
  void cancelMonitoring() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    if (kDebugMode) {
      print('订单状态监控已取消');
    }
  }

  // 获取订单详情的函数
  Future getOrderDetails(String tradeNo, String accessToken) async {
    // 这里是获取订单详情的逻辑，返回订单详情结果
    final orderDetails =
        await OrderService().getOrderDetails(tradeNo, accessToken);
    return orderDetails;
  }
}
