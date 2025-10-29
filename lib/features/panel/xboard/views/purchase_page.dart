import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/common/adaptive_root_scaffold.dart';
import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/services/purchase_service.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/purchase_viewmodel.dart';

import 'package:hiddify/features/panel/xboard/views/components/dialog/purchase_details_dialog.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 24,
                    ),
                    itemCount: viewModel.plans.length,
                    itemBuilder: (context, index) {
                      final plan = viewModel.plans[index];
                      return _buildPlanCard(plan, t, context, ref, theme, index);
                    },
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
}
