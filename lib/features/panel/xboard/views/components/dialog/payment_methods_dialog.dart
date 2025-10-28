// payment_methods_dialog.dart

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/services/subscription.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/dialog_viewmodel/payment_methods_viewmodel.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/dialog_viewmodel/payment_methods_viewmodel_provider.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
// 导入 ViewModel Provider

class PaymentMethodsDialog extends ConsumerStatefulWidget {
  final String tradeNo;
  final List<dynamic> paymentMethods;
  final double totalAmount;
  final Translations t;
  final WidgetRef ref;

  const PaymentMethodsDialog({
    super.key,
    required this.tradeNo,
    required this.paymentMethods,
    required this.totalAmount,
    required this.t,
    required this.ref,
  });

  @override
  _PaymentMethodsDialogState createState() => _PaymentMethodsDialogState();
}

class _PaymentMethodsDialogState extends ConsumerState<PaymentMethodsDialog> {
  late final PaymentMethodsViewModelParams _params;
  late final AutoDisposeChangeNotifierProvider<PaymentMethodsViewModel>
      _provider;

  @override
  void initState() {
    super.initState();

    _params = PaymentMethodsViewModelParams(
      tradeNo: widget.tradeNo,
      totalAmount: widget.totalAmount,
      onPaymentSuccess: () {
        // 检查 widget 是否还挂载
        if (!mounted) return;

        final t = ref.read(translationsProvider); // 使用 ref.read 而不是 ref.watch
        // 支付成功回调
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.purchase.orderSuccess)),
        );
        Subscription.updateSubscription(context, widget.ref);
        Navigator.of(context).pop(); // 关闭支付方式弹窗
        Navigator.of(context).pop(); // 关闭购买详情弹窗
      },
    );

    _provider = paymentMethodsViewModelProvider(_params);
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(_provider);
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 10,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      FluentIcons.payment_24_filled,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.purchase.selectPaymentMethod,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      FluentIcons.dismiss_24_filled,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // 内容区域
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.paymentMethods.map((method) {
                    final Map<String, dynamic> paymentMethod =
                        method as Map<String, dynamic>;

                    final feePercent =
                        paymentMethod['handling_fee_percent'] != null
                            ? double.tryParse(
                                    paymentMethod['handling_fee_percent']
                                        .toString(),
                                ) ??
                                0.0
                            : 0.0;
                    final handlingFee = widget.totalAmount * feePercent / 100;
                    final totalPrice = widget.totalAmount + handlingFee;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(context).pop();
                            viewModel.handlePayment(paymentMethod);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 支付方式名称
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        FluentIcons.wallet_credit_card_24_filled,
                                        color: theme.colorScheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        paymentMethod['name']?.toString() ??
                                            t.purchase.unknown,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      FluentIcons.chevron_right_24_regular,
                                      color: Colors.grey[400],
                                      size: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // 价格信息
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      // 总价格（最突出）
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${t.purchase.totalPrice}:',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            '¥${totalPrice.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Divider(
                                        color: Colors.grey[300],
                                        thickness: 0.5,
                                      ),
                                      const SizedBox(height: 8),
                                      // 套餐价格
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${t.purchase.total}:',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          Text(
                                            '${widget.totalAmount.toStringAsFixed(2)} ${widget.t.purchase.rmb}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // 手续费
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${t.purchase.fee}: ${feePercent.toStringAsFixed(2)}%',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          Text(
                                            '${handlingFee.toStringAsFixed(2)} ${widget.t.purchase.rmb}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            // 底部关闭按钮
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(FluentIcons.dismiss_24_regular, size: 18),
                  label: Text(
                    t.purchase.close,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
