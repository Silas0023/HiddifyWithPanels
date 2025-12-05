// purchase_details_view_model.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/order_service.dart';
import 'package:hiddify/features/panel/xboard/services/purchase_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/user_storage.dart';

class PurchaseDetailsViewModel extends ChangeNotifier {
  final String? planValue; // 套餐的 appleValue
  String? tradeNo;
  String? payUrl; // 支付链接
  bool isLoading = false;

  final PurchaseService _purchaseService = PurchaseService();
  final OrderService _orderService = OrderService();
  Timer? _statusCheckTimer;
  bool _isDisposed = false;

  PurchaseDetailsViewModel({
    this.planValue,
  });

  @override
  void dispose() {
    _isDisposed = true;
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  /// 开始监控订单支付状态
  /// [onPaymentSuccess] 支付成功回调
  void startMonitoringOrderStatus(VoidCallback onPaymentSuccess) {
    if (tradeNo == null) return;

    // 每3秒检查一次订单状态，最多检查60次（3分钟）
    int checkCount = 0;
    const maxChecks = 60;

    _statusCheckTimer?.cancel();
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      checkCount++;
      if (checkCount > maxChecks) {
        timer.cancel();
        if (kDebugMode) {
          print('Order status check timeout after $maxChecks attempts');
        }
        return;
      }

      final isPaid = await checkOrderStatus();
      if (isPaid) {
        timer.cancel();
        onPaymentSuccess();
      }
    });
  }

  /// 停止监控订单状态
  void stopMonitoringOrderStatus() {
    _statusCheckTimer?.cancel();
  }

  /// 检查订单支付状态
  /// 返回 true 表示已支付
  Future<bool> checkOrderStatus() async {
    if (tradeNo == null) return false;

    try {
      final accessToken = await getToken();
      if (accessToken == null) return false;

      final response = await _orderService.checkOrderStatus(accessToken, tradeNo!);

      if (kDebugMode) {
        print('checkOrderStatus response: $response');
      }

      // data 直接返回 true/false 表示支付状态
      if (response['code'] == 200) {
        final isPaid = response['data'] == true;
        if (isPaid) {
          if (kDebugMode) {
            print('Order $tradeNo is paid!');
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('checkOrderStatus error: $e');
      }
      return false;
    }
  }

  /// 创建订单并返回是否成功
  /// [payType] 支付类型: 1=支付宝, 2=微信支付
  Future<bool> createOrder(int payType) async {
    _setLoading(true);

    try {
      final accessToken = await getToken();
      if (accessToken == null) {
        if (kDebugMode) {
          print("createOrder: Access token is null");
        }
        _setLoading(false);
        return false;
      }

      // 获取用户ID
      final userId = await getUserId();
      if (userId == null || userId <= 0) {
        if (kDebugMode) {
          print("createOrder: User ID is null or invalid");
        }
        _setLoading(false);
        return false;
      }

      if (planValue == null || planValue!.isEmpty) {
        if (kDebugMode) {
          print("createOrder: planValue is null or empty");
        }
        _setLoading(false);
        return false;
      }

      // 创建新订单
      if (kDebugMode) {
        print('createOrder: Creating order - userId: $userId, planValue: $planValue, payType: $payType');
      }
      final orderResponse = await _purchaseService.createOrder(
        userId,
        planValue!,
        payType,
        accessToken,
      );

      if (kDebugMode) {
        print('createOrder: Order response: $orderResponse');
      }

      if (orderResponse != null && orderResponse['data'] != null) {
        final data = orderResponse['data'] as Map<String, dynamic>;
        tradeNo = data['tradeNo']?.toString();
        payUrl = data['payUrl']?.toString();
        if (kDebugMode) {
          print("createOrder: Order created successfully, tradeNo: $tradeNo, payUrl: $payUrl");
        }
        _setLoading(false);
        return true;
      } else {
        if (kDebugMode) {
          print('createOrder: Order creation failed');
          print('createOrder: Response: $orderResponse');
        }
        _setLoading(false);
        return false;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('createOrder error: $e');
        print('createOrder stack trace: $stackTrace');
      }
      _setLoading(false);
      return false;
    }
  }
}
