import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/common/adaptive_root_scaffold.dart';
import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/services/future_provider.dart';
import 'package:hiddify/features/panel/xboard/services/purchase_service.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/purchase_viewmodel.dart';

import 'package:hiddify/features/panel/xboard/views/components/dialog/purchase_details_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

final purchaseViewModelProvider = ChangeNotifierProvider(
  (ref) => PurchaseViewModel(purchaseService: PurchaseService()),
);

class PurchasePage extends ConsumerStatefulWidget {
  const PurchasePage({super.key});

  @override
  _PurchasePageState createState() => _PurchasePageState();
}

class _PurchasePageState extends ConsumerState<PurchasePage> {
  @override
  void initState() {
    super.initState();
    // Delay the provider modification until after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchaseViewModelProvider).fetchPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final viewModel = ref.watch(purchaseViewModelProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isSmallScreen = Breakpoints.small.isActive(context);

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        // 在小窗口时显示左上角菜单按钮
        leading: isSmallScreen
            ? Builder(
                builder: (context) => IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  tooltip: '菜单',
                  onPressed: () {
                    RootScaffold.stateKey.currentState?.openDrawer();
                  },
                ),
              )
            : null,
        title: Text(
          t.purchase.pageTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(purchaseViewModelProvider).fetchPlans();
        },
        child: Builder(
          builder: (context) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (viewModel.errorMessage != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FluentIcons.error_circle_24_regular,
                      size: 64,
                      color: Colors.red[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.purchase.fetchPlansError,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      viewModel.errorMessage!,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            } else if (viewModel.plans.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FluentIcons.box_24_regular,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.purchase.noPlans,
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            } else {
              // 获取用户信息
              final userInfoAsync = ref.watch(userTokenInfoProvider);

              return LayoutBuilder(
                builder: (context, constraints) {
                  // 根据屏幕宽度计算列数和卡片尺寸
                  int crossAxisCount;
                  double childAspectRatio;

                  if (constraints.maxWidth > 1400) {
                    crossAxisCount = 3; // 超大屏幕：3列
                    childAspectRatio = 0.65; // 增加高度
                  } else if (constraints.maxWidth > 900) {
                    crossAxisCount = 2; // 中等屏幕：2列
                    childAspectRatio = 0.6; // 增加高度
                  } else {
                    crossAxisCount = 1; // 小屏幕：1列
                    childAspectRatio = 0.75; // 增加高度
                  }

                  return CustomScrollView(
                    slivers: [
                      // 用户信息卡片
                      SliverToBoxAdapter(
                        child: userInfoAsync.when(
                          data: (userInfo) {
                            if (userInfo == null) return const SizedBox.shrink();

                            // 通过 planId 找到对应的套餐名称
                            final currentPlan = viewModel.plans.firstWhere(
                              (plan) => plan.id == userInfo.planId,
                              orElse: () => Plan(
                                id: 0,
                                name: '免费套餐',
                                content: '',
                              ),
                            );

                            return _buildUserInfoCard(
                              userInfo,
                              currentPlan,
                              isDark,
                              t,
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ),
                      // 套餐网格
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: childAspectRatio,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 24,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final plan = viewModel.plans[index];
                              return _buildPlanCard(plan, t, context, ref, theme, index);
                            },
                            childCount: viewModel.plans.length,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    Plan plan,
    Translations t,
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    int index,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    // 为每个卡片分配不同的渐变色
    final gradients = [
      [Colors.blue[700]!, Colors.blue[500]!],
      [Colors.purple[700]!, Colors.purple[500]!],
      [Colors.orange[700]!, Colors.orange[500]!],
      [Colors.teal[700]!, Colors.teal[500]!],
      [Colors.pink[700]!, Colors.pink[500]!],
    ];
    final gradientColors = gradients[index % gradients.length];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.25),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部渐变色头部
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          plan.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          FluentIcons.star_24_filled,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 价格信息
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (plan.halfYearPrice != null && plan.halfYearPrice! > 0)
                        Text(
                          '¥${plan.halfYearPrice!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        )
                      else if (plan.monthPrice != null && plan.monthPrice! > 0)
                        Text(
                          '¥${plan.monthPrice!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        )
                      else if (plan.quarterPrice != null && plan.quarterPrice! > 0)
                        Text(
                          '¥${plan.quarterPrice!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        )
                      else if (plan.yearPrice != null && plan.yearPrice! > 0)
                        Text(
                          '¥${plan.yearPrice!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          t.purchase.rmb,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 套餐详情内容
            Expanded(
              child: Container(
                color: isDark ? Colors.grey[800] : Colors.white,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildModernStyledContent(
                          plan.content ?? t.purchase.noData,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 订阅按钮
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          showPurchaseDialog(context, plan, t, ref);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: gradientColors[0],
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: gradientColors[0].withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              t.purchase.subscribe,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              FluentIcons.arrow_right_24_filled,
                              size: 20,
                            ),
                          ],
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

  Widget _buildModernStyledContent(String content) {
    final lines = content.split('\n').where((line) => line.trim().isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 7),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.blue[400],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  line.trim(),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUserInfoCard(
    UserInfo userInfo,
    Plan currentPlan,
    bool isDark,
    Translations t,
  ) {
    // 格式化过期时间
    String formatExpireTime(int? expiredAt) {
      if (expiredAt == null) return '永久有效';
      final expireDate = DateTime.fromMillisecondsSinceEpoch(expiredAt * 1000);
      final now = DateTime.now();
      final difference = expireDate.difference(now);

      if (difference.inDays < 0) {
        return '已过期';
      } else if (difference.inDays == 0) {
        return '今天过期';
      } else if (difference.inDays == 1) {
        return '明天过期';
      } else {
        final formatter = DateFormat('yyyy年MM月dd日');
        return formatter.format(expireDate);
      }
    }

    // 获取剩余天数
    int? getRemainingDays(int? expiredAt) {
      if (expiredAt == null) return null;
      final expireDate = DateTime.fromMillisecondsSinceEpoch(expiredAt * 1000);
      final now = DateTime.now();
      final difference = expireDate.difference(now);
      return difference.inDays;
    }

    final remainingDays = getRemainingDays(userInfo.expiredAt);
    final isExpired = remainingDays != null && remainingDays < 0;
    final isExpiringSoon = remainingDays != null && remainingDays >= 0 && remainingDays <= 7;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E3A5F),
                  const Color(0xFF0D2847),
                ]
              : [
                  const Color(0xFFEFF6FF),
                  const Color(0xFFDBEAFE),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : const Color(0xFF93C5FD),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF3B82F6)).withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题行
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF3B82F6),
                        Color(0xFF2563EB),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    FluentIcons.person_24_filled,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '当前套餐',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentPlan.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // 过期时间信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpired
                        ? FluentIcons.warning_24_filled
                        : isExpiringSoon
                            ? FluentIcons.clock_alarm_24_filled
                            : FluentIcons.calendar_checkmark_24_filled,
                    color: isExpired
                        ? Colors.red[400]
                        : isExpiringSoon
                            ? Colors.orange[400]
                            : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6)),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '过期时间',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatExpireTime(userInfo.expiredAt),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isExpired
                                ? Colors.red[400]
                                : isExpiringSoon
                                    ? Colors.orange[400]
                                    : (isDark ? Colors.white : const Color(0xFF1E293B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 剩余天数标签
                  if (remainingDays != null && remainingDays >= 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isExpiringSoon
                            ? Colors.orange[400]
                            : const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '剩余 $remainingDays 天',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
