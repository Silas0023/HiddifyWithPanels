// purchase_details_dialog.dart

// ignore_for_file: use_build_context_synchronously

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/app_router.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/services/subscription.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/dialog_viewmodel/purchase_details_viewmodel.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/dialog_viewmodel/purchase_details_viewmodel_provider.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/dialog_viewmodel/payment_methods_viewmodel.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/dialog_viewmodel/payment_methods_viewmodel_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void showPurchaseDialog(
    BuildContext context,
    Plan plan,
    Translations t,
    WidgetRef ref,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return PurchaseDetailsDialog(plan: plan, t: t, ref: ref);
    },
  );
}

class PurchaseDetailsDialog extends ConsumerStatefulWidget {
  final Plan plan;
  final Translations t;
  final WidgetRef ref;

  const PurchaseDetailsDialog({
    super.key,
    required this.plan,
    required this.t,
    required this.ref,
  });

  @override
  _PurchaseDetailsDialogState createState() => _PurchaseDetailsDialogState();
}

class _PurchaseDetailsDialogState extends ConsumerState<PurchaseDetailsDialog> {
  late final PurchaseDetailsViewModelParams _params;
  late final AutoDisposeChangeNotifierProvider<PurchaseDetailsViewModel>
      _provider;

  @override
  void initState() {
    super.initState();

    _params = PurchaseDetailsViewModelParams(
      planId: widget.plan.id,
    );

    _provider = purchaseDetailsViewModelProvider(_params);

    // 初始化选择的价格和周期
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = ref.read(_provider);
      final cheapestPrice = _findCheapestPrice();
      final cheapestPeriod = _findCheapestPeriod(cheapestPrice);
      viewModel.setSelectedPrice(cheapestPrice, cheapestPeriod);
    });
  }

  double? _findCheapestPrice() {
    final prices = [
      widget.plan.monthPrice,
      widget.plan.quarterPrice,
      widget.plan.halfYearPrice,
      widget.plan.yearPrice,
      widget.plan.twoYearPrice,
      widget.plan.threeYearPrice,
      widget.plan.onetimePrice,
    ].where((price) => price != null).toList();

    if (prices.isNotEmpty) {
      return prices.reduce((a, b) => a! < b! ? a : b);
    }
    return null;
  }

  String? _findCheapestPeriod(double? cheapestPrice) {
    if (cheapestPrice == widget.plan.monthPrice) return 'month_price';
    if (cheapestPrice == widget.plan.quarterPrice) return 'quarter_price';
    if (cheapestPrice == widget.plan.halfYearPrice) return 'half_year_price';
    if (cheapestPrice == widget.plan.yearPrice) return 'year_price';
    if (cheapestPrice == widget.plan.twoYearPrice) return 'two_year_price';
    if (cheapestPrice == widget.plan.threeYearPrice) return 'three_year_price';
    if (cheapestPrice == widget.plan.onetimePrice) return 'onetime_price';
    return null;
  }

  Widget _buildPriceRadio(
      String label,
      double price,
      String period,
      PurchaseDetailsViewModel vm,
      ThemeData theme,
  ) {
    final isSelected = vm.selectedPrice == price;
    // 注意：price 从 Plan 模型来，已经是元为单位了
    final priceInYuan = price;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? theme.colorScheme.primary.withOpacity(0.08)
            : Colors.transparent,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: RadioListTile<double>(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? theme.colorScheme.primary : Colors.black87,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '¥${priceInYuan.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        value: price,
        groupValue: vm.selectedPrice,
        activeColor: theme.colorScheme.primary,
        onChanged: (double? value) {
          vm.setSelectedPrice(value, period);
        },
      ),
    );
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
        constraints: const BoxConstraints(maxWidth: 500),
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
                      FluentIcons.tag_24_filled,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.plan.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          FluentIcons.calendar_clock_24_regular,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.purchase.subscriptionDuration,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (widget.plan.monthPrice != null)
                      _buildPriceRadio(
                        widget.t.purchase.monthPrice,
                        widget.plan.monthPrice!,
                        'month_price',
                        viewModel,
                        theme,
                      ),
                    if (widget.plan.quarterPrice != null)
                      _buildPriceRadio(
                        widget.t.purchase.quarterPrice,
                        widget.plan.quarterPrice!,
                        'quarter_price',
                        viewModel,
                        theme,
                      ),
                    if (widget.plan.halfYearPrice != null)
                      _buildPriceRadio(
                        widget.t.purchase.halfYearPrice,
                        widget.plan.halfYearPrice!,
                        'half_year_price',
                        viewModel,
                        theme,
                      ),
                    if (widget.plan.yearPrice != null)
                      _buildPriceRadio(
                        widget.t.purchase.yearPrice,
                        widget.plan.yearPrice!,
                        'year_price',
                        viewModel,
                        theme,
                      ),
                    if (widget.plan.twoYearPrice != null)
                      _buildPriceRadio(
                        widget.t.purchase.twoYearPrice,
                        widget.plan.twoYearPrice!,
                        'two_year_price',
                        viewModel,
                        theme,
                      ),
                    if (widget.plan.threeYearPrice != null)
                      _buildPriceRadio(
                        widget.t.purchase.threeYearPrice,
                        widget.plan.threeYearPrice!,
                        'three_year_price',
                        viewModel,
                        theme,
                      ),
                    if (widget.plan.onetimePrice != null)
                      _buildPriceRadio(
                        widget.t.purchase.onetimePrice,
                        widget.plan.onetimePrice!,
                        'onetime_price',
                        viewModel,
                        theme,
                      ),
                    const SizedBox(height: 8),
                    // 总价显示
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${t.purchase.total}:",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            viewModel.selectedPrice != null
                                ? '¥${viewModel.selectedPrice!.toStringAsFixed(2)}'
                                : widget.t.purchase.noData,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 订阅按钮
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: viewModel.isLoading
                            ? null
                            : () async {
                                if (viewModel.selectedPrice != null &&
                                    viewModel.selectedPeriod != null) {
                                  final paymentMethods =
                                      await viewModel.handleSubscribe();
                                  if (paymentMethods.isNotEmpty) {
                                    // 关闭购买详情对话框
                                    Navigator.of(context).pop();

                                    // 直接使用第一个支付方式打开支付页面
                                    final firstPaymentMethod = paymentMethods[0] as Map<String, dynamic>;

                                    // 获取 ViewModel 并直接触发支付
                                    final paymentParams = PaymentMethodsViewModelParams(
                                      tradeNo: viewModel.tradeNo!,
                                      totalAmount: viewModel.selectedPrice!,
                                      ref: widget.ref,
                                      onPaymentSuccess: () async {
                                        // 使用全局 rootNavigatorKey 获取有效的 context
                                        final navigatorContext = rootNavigatorKey.currentContext;
                                        if (navigatorContext == null) {
                                          if (kDebugMode) {
                                            print('[PaymentSuccess] 无法获取有效的 context');
                                          }
                                          return;
                                        }

                                        try {
                                          // 更新订阅（会获取新订阅链接、删除旧订阅、添加新订阅并设置为 activeProfile）
                                          if (kDebugMode) {
                                            print('[PaymentSuccess] 开始更新订阅配置...');
                                          }

                                          await Subscription.updateSubscription(navigatorContext, widget.ref);

                                          if (kDebugMode) {
                                            print('[PaymentSuccess] 订阅配置更新完成，activeProfile 已设置');
                                          }
                                        } catch (e) {
                                          if (kDebugMode) {
                                            print('[PaymentSuccess] 更新订阅配置失败: $e');
                                          }
                                          // 即使订阅更新失败，也继续显示成功提示，因为用户已经购买成功
                                        }

                                        // 显示购买成功对话框，引导用户前往首页连接VPN
                                        await showDialog(
                                          context: navigatorContext,
                                          barrierDismissible: false,
                                          builder: (dialogContext) => AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // 成功图标
                                                Container(
                                                  width: 80,
                                                  height: 80,
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                      colors: [
                                                        Color(0xFF10B981),
                                                        Color(0xFF059669),
                                                      ],
                                                    ),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFF10B981).withOpacity(0.3),
                                                        blurRadius: 20,
                                                        offset: const Offset(0, 8),
                                                      ),
                                                    ],
                                                  ),
                                                  child: const Icon(
                                                    FluentIcons.checkmark_circle_24_filled,
                                                    color: Colors.white,
                                                    size: 48,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                // 标题
                                                const Text(
                                                  '购买成功！',
                                                  style: TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                // 描述
                                                const Text(
                                                  '订阅已激活，请前往首页连接VPN开始使用',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.black54,
                                                    height: 1.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                // 前往首页按钮
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      Navigator.of(dialogContext).pop(); // 关闭成功对话框
                                                      // 使用 go_router 跳转到首页
                                                      const HomeRoute().go(navigatorContext);
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: const Color(0xFF10B981),
                                                      foregroundColor: Colors.white,
                                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                      elevation: 0,
                                                    ),
                                                    child: const Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(FluentIcons.home_24_filled, size: 20),
                                                        SizedBox(width: 8),
                                                        Text(
                                                          '前往首页',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );

                                    final paymentProvider = paymentMethodsViewModelProvider(paymentParams);
                                    final paymentViewModel = widget.ref.read(paymentProvider);

                                    // 直接调用支付处理
                                    paymentViewModel.handlePayment(firstPaymentMethod);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(t.payments.noPayments),
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(t.payments.noSuchPlan),
                                    ),
                                  );
                                }
                              },
                        icon: viewModel.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(
                                FluentIcons.checkmark_circle_24_filled,
                                size: 20,
                              ),
                        label: Text(
                          viewModel.isLoading
                              ? t.appCenter.loading
                              : widget.t.purchase.subscribe,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
