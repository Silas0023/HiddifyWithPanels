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
import 'package:hiddify/features/panel/xboard/viewmodels/user_info_viewmodel.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // 支付方式相关状态
  List<dynamic> _paymentMethods = [];
  Map<String, dynamic>? _selectedPaymentMethod;
  bool _paymentMethodsLoaded = false;

  @override
  void initState() {
    super.initState();

    _params = PurchaseDetailsViewModelParams(
      planValue: widget.plan.appleValue,
    );

    _provider = purchaseDetailsViewModelProvider(_params);

    // 加载支付方式
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPaymentMethods();
    });
  }

  // 加载支付方式（写死支付宝和微信支付）
  void _loadPaymentMethods() {
    // 硬编码支付方式，id对应payType: 1=支付宝, 2=微信支付
    final hardcodedPaymentMethods = [
      {
        'id': 1,
        'name': '支付宝',
        'payment': 'alipay',
        'payType': 1,
      },
      {
        'id': 2,
        'name': '微信支付',
        'payment': 'wechat',
        'payType': 2,
      },
    ];

    setState(() {
      _paymentMethods = hardcodedPaymentMethods;
      _paymentMethodsLoaded = true;
      // 默认选中支付宝
      _selectedPaymentMethod = hardcodedPaymentMethods[0];
    });
  }

  // 构建支付方式图标
  Widget _buildPaymentIcon(String methodName) {
    final name = methodName.toLowerCase();
    Color iconColor;
    IconData iconData;

    if (name.contains('支付宝') || name.contains('alipay') || name.contains('ali')) {
      iconColor = const Color(0xFF1677FF);
      iconData = FluentIcons.wallet_24_filled;
    } else if (name.contains('微信') || name.contains('wechat') || name.contains('weixin')) {
      iconColor = const Color(0xFF07C160);
      iconData = FluentIcons.chat_24_filled;
    } else if (name.contains('usdt') || name.contains('crypto') || name.contains('虚拟货币')) {
      iconColor = const Color(0xFF26A17B);
      iconData = FluentIcons.currency_dollar_euro_24_filled;
    } else {
      iconColor = Colors.grey;
      iconData = FluentIcons.payment_24_filled;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 18,
      ),
    );
  }

  // 支付成功处理
  Future<void> _handlePaymentSuccess(WidgetRef ref) async {
    if (kDebugMode) {
      print('[PaymentSuccess] 支付成功，开始更新数据...');
    }

    try {
      // 刷新用户信息
      await ref.read(userInfoViewModelProvider.notifier).refresh();
      if (kDebugMode) {
        print('[PaymentSuccess] 用户信息已刷新');
      }

      // 更新订阅
      final navContext = rootNavigatorKey.currentContext;
      if (navContext != null) {
        await Subscription.updateSubscription(navContext, ref);
      }
      if (kDebugMode) {
        print('[PaymentSuccess] 订阅更新完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PaymentSuccess] 更新数据失败: $e');
      }
    }

    // 显示购买成功对话框
    final successContext = rootNavigatorKey.currentContext;
    if (successContext == null) return;

    await showDialog(
      context: successContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
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
            const Text(
              '购买套餐成功！',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '套餐已激活，请前往首页连接VPN',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  const HomeRoute().go(successContext);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('前往首页', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
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
              theme.colorScheme.primary.withValues(alpha: 0.05),
              theme.colorScheme.secondary.withValues(alpha: 0.05),
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
                    theme.colorScheme.primary.withValues(alpha: 0.8),
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
                      color: Colors.white.withValues(alpha: 0.2),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.plan.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.plan.tag != null)
                          Text(
                            widget.plan.tag!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 14,
                            ),
                          ),
                      ],
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
                    // 套餐内容
                    if (widget.plan.content != null && widget.plan.content!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            FluentIcons.list_24_regular,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '套餐详情',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.plan.content!,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // 支付方式选择（横向一行显示）
                    if (_paymentMethodsLoaded && _paymentMethods.isNotEmpty) ...[
                      Row(
                        children: _paymentMethods.map((method) {
                          final paymentMethod = method as Map<String, dynamic>;
                          final isSelected = _selectedPaymentMethod == paymentMethod;
                          final methodName = paymentMethod['name']?.toString() ?? '未知';

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedPaymentMethod = paymentMethod;
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: _paymentMethods.indexOf(method) < _paymentMethods.length - 1 ? 10 : 0,
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.primary.withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : Colors.grey.withValues(alpha: 0.3),
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // 支付方式图标
                                    _buildPaymentIcon(methodName),
                                    const SizedBox(width: 8),
                                    // 支付方式名称
                                    Text(
                                      methodName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // 立即支付按钮（带价格）
                    Row(
                      children: [
                        // 价格显示
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '¥${widget.plan.currentPrice}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 支付按钮
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: (viewModel.isLoading || _selectedPaymentMethod == null)
                                  ? null
                                  : () async {
                                      // 使用选中的支付方式
                                      final selectedMethod = _selectedPaymentMethod!;
                                      final payType = selectedMethod['payType'] as int? ?? 1;

                                      // 创建订单（传入payType）
                                      final success = await viewModel.createOrder(payType);
                                      if (!success) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('创建订单失败，请重试')),
                                          );
                                        }
                                        return;
                                      }

                                      // 检查是否有支付链接
                                      if (viewModel.payUrl == null || viewModel.payUrl!.isEmpty) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('获取支付链接失败，请重试')),
                                          );
                                        }
                                        return;
                                      }

                                      // 关闭购买详情对话框
                                      if (mounted) {
                                        Navigator.of(context).pop();
                                      }

                                      // 直接打开支付链接
                                      final Uri payUri = Uri.parse(viewModel.payUrl!);
                                      if (kDebugMode) {
                                        print('Opening payment URL: ${viewModel.payUrl}');
                                      }
                                      await launchUrl(payUri, mode: LaunchMode.externalApplication);

                                      // 获取有效的 context
                                      final navigatorContext = rootNavigatorKey.currentContext;
                                      if (navigatorContext == null) return;

                                      // 显示订单状态检查弹窗
                                      showDialog(
                                        context: navigatorContext,
                                        barrierDismissible: false,
                                        builder: (checkingContext) => PopScope(
                                          canPop: false,
                                          child: AlertDialog(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // 图标
                                                Container(
                                                  width: 80,
                                                  height: 80,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    FluentIcons.payment_24_filled,
                                                    color: Color(0xFF3B82F6),
                                                    size: 40,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),
                                                const Text(
                                                  '等待支付完成',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                const Text(
                                                  '请在浏览器中完成支付\n支付完成后请点击「检查订单状态」按钮',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                                                ),
                                                const SizedBox(height: 24),
                                                // 按钮行：检查订单状态 | 取消支付
                                                Row(
                                                  children: [
                                                    // 检查订单状态按钮
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        onPressed: () async {
                                                          // 检查订单状态
                                                          final isPaid = await viewModel.checkOrderStatus();
                                                          if (isPaid) {
                                                            // 关闭当前弹窗
                                                            Navigator.of(checkingContext).pop();
                                                            // 触发支付成功回调
                                                            _handlePaymentSuccess(widget.ref);
                                                          } else {
                                                            // 显示未支付提示
                                                            ScaffoldMessenger.of(checkingContext).showSnackBar(
                                                              const SnackBar(
                                                                content: Text('订单尚未支付，请完成支付后再试'),
                                                                duration: Duration(seconds: 2),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: const Color(0xFF3B82F6),
                                                          foregroundColor: Colors.white,
                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                        ),
                                                        child: const Text('检查订单状态', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    // 取消支付按钮
                                                    Expanded(
                                                      child: OutlinedButton(
                                                        onPressed: () {
                                                          Navigator.of(checkingContext).pop();
                                                        },
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: Colors.grey.shade600,
                                                          side: BorderSide(color: Colors.grey.shade400),
                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                        ),
                                                        child: const Text('取消支付', style: TextStyle(fontSize: 14)),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
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
                                FluentIcons.payment_24_filled,
                                size: 20,
                              ),
                        label: Text(
                          viewModel.isLoading
                              ? t.appCenter.loading
                              : (_selectedPaymentMethod == null ? '请选择支付方式' : '立即支付'),
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
                        ),
                      ],
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
