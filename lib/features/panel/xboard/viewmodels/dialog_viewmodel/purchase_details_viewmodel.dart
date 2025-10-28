// purchase_details_view_model.dart

import 'package:flutter/foundation.dart';
import 'package:hiddify/features/panel/xboard/models/order_model.dart';
import 'package:hiddify/features/panel/xboard/services/http_service/order_service.dart';
import 'package:hiddify/features/panel/xboard/services/purchase_service.dart';
import 'package:hiddify/features/panel/xboard/utils/storage/token_storage.dart';

class PurchaseDetailsViewModel extends ChangeNotifier {
  final int planId;
  String? selectedPeriod;
  double? selectedPrice;
  String? tradeNo;
  bool isLoading = false;

  final PurchaseService _purchaseService = PurchaseService();
  final OrderService _orderService = OrderService();

  PurchaseDetailsViewModel({
    required this.planId,
    this.selectedPeriod,
    this.selectedPrice,
  });

  void setSelectedPrice(double? price, String? period) {
    selectedPrice = price;
    selectedPeriod = period;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  Future<List<dynamic>> handleSubscribe() async {
    _setLoading(true);

    try {
      final accessToken = await getToken();
      if (accessToken == null) {
        if (kDebugMode) {
          print("handleSubscribe: Access token is null");
        }
        _setLoading(false);
        return [];
      }
      // 检查未支付的订单
      if (kDebugMode) {
        print('handleSubscribe: Fetching user orders...');
      }

      List<Order> orders = [];
      try {
        orders = await _orderService.fetchUserOrders(accessToken);
        if (kDebugMode) {
          print('handleSubscribe: Found ${orders.length} orders');
        }
      } catch (e) {
        if (kDebugMode) {
          print('handleSubscribe: Error fetching orders: $e');
          print('handleSubscribe: Continuing without canceling orders...');
        }
        // Continue even if we can't fetch orders
      }

      // Cancel unpaid orders if any were found
      for (final order in orders) {
        if (kDebugMode) {
          print('handleSubscribe: Order ${order.tradeNo} status: ${order.status}');
        }
        if (order.status == 0 && order.tradeNo != null) {
          try {
            await _orderService.cancelOrder(order.tradeNo!, accessToken);
            if (kDebugMode) {
              print('handleSubscribe: Cancelled unpaid order ${order.tradeNo}');
            }
          } catch (e) {
            if (kDebugMode) {
              print('handleSubscribe: Error canceling order ${order.tradeNo}: $e');
              print('handleSubscribe: Continuing...');
            }
            // Continue even if we can't cancel an order
          }
        }
      }

      // 创建新订单
      if (kDebugMode) {
        print('handleSubscribe: Creating order for plan $planId, period $selectedPeriod');
      }
      final orderResponse = await _purchaseService.createOrder(
        planId,
        selectedPeriod!,
        accessToken,
      );

      if (kDebugMode) {
        print('handleSubscribe: Order response: $orderResponse');
      }

      if (orderResponse != null && orderResponse['data'] != null) {
        tradeNo = orderResponse['data']?.toString();
        if (kDebugMode) {
          print("handleSubscribe: Order created successfully, tradeNo: $tradeNo");
        }

        // 获取支付方式
        if (kDebugMode) {
          print('handleSubscribe: Fetching payment methods...');
        }
        final paymentMethods =
            await _purchaseService.getPaymentMethods(accessToken);

        if (kDebugMode) {
          print('handleSubscribe: Got ${paymentMethods.length} payment methods');
        }

        _setLoading(false);
        return paymentMethods;
      } else {
        if (kDebugMode) {
          print('handleSubscribe: Order creation failed');
          print('handleSubscribe: Response: $orderResponse');
        }
        _setLoading(false);
        return [];
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('handleSubscribe error: $e');
        print('handleSubscribe stack trace: $stackTrace');
      }
      _setLoading(false);
      return [];
    }
  }
}
