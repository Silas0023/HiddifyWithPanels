import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/services/future_provider.dart';
// 隐藏余额和佣金功能
// import 'package:hiddify/features/panel/xboard/views/components/user_info/account_balance_card.dart';
// 隐藏邀请码功能
// import 'package:hiddify/features/panel/xboard/views/components/user_info/invite_code_section.dart';
import 'package:hiddify/features/panel/xboard/utils/logout_dialog.dart';
// 隐藏重置订阅按钮功能
// import 'package:hiddify/features/panel/xboard/views/components/user_info/reset_subscription_button.dart';
import 'package:hiddify/features/panel/xboard/views/components/user_info/traffic_chart_card.dart';
import 'package:hiddify/features/panel/xboard/views/components/user_info/user_info_card.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserInfoPage extends ConsumerStatefulWidget {
  const UserInfoPage({super.key});

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends ConsumerState<UserInfoPage> {
  // 移除自动刷新，避免每次进入页面都重新加载
  // 保留手动刷新功能
  void _refreshData() {
    // 刷新用户信息
    // ignore: unused_result
    ref.refresh(userTokenInfoProvider);
    // 不再需要刷新邀请码列表
    // ref.refresh(inviteCodesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        centerTitle: true,
        title: Text(
          t.userInfo.pageTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              FluentIcons.arrow_sync_24_regular,
              color: theme.colorScheme.primary,
            ),
            onPressed: _refreshData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder(
        // 只加载用户信息
        future: ref.watch(userTokenInfoProvider.future),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // 显示加载指示器
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '加载中...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            // 显示错误信息
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
                    t.userInfo.fetchUserInfoError,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // 如果数据加载成功，显示整个视图
          final userInfo = snapshot.data;

          // 如果没有用户信息，显示错误
          if (userInfo == null) {
            return Center(
              child: Text(
                '无法加载用户信息',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refreshData();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const UserInfoCard(),
                  const SizedBox(height: 16),
                  // 流量信息 - 折叠面板
                  _TrafficCollapsiblePanel(
                    userInfo: userInfo,
                    t: t,
                    isDark: isDark,
                    theme: theme,
                  ),
                  const SizedBox(height: 16),
                  // 隐藏余额和佣金卡片
                  // const AccountBalanceCard(),
                  // const SizedBox(height: 16),
                  // 隐藏邀请码部分
                  // const InviteCodeSection(),
                  // const SizedBox(height: 16),
                  // 隐藏重置订阅按钮
                  // const ResetSubscriptionButton(),
                  const SizedBox(height: 16),
                  // 退出登录按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const LogoutDialog(),
                        );
                      },
                      icon: const Icon(FluentIcons.sign_out_20_filled),
                      label: const Text(
                        '退出登录',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// 流量信息折叠面板
class _TrafficCollapsiblePanel extends StatefulWidget {
  final UserInfo userInfo;
  final Translations t;
  final bool isDark;
  final ThemeData theme;

  const _TrafficCollapsiblePanel({
    required this.userInfo,
    required this.t,
    required this.isDark,
    required this.theme,
  });

  @override
  State<_TrafficCollapsiblePanel> createState() =>
      _TrafficCollapsiblePanelState();
}

class _TrafficCollapsiblePanelState extends State<_TrafficCollapsiblePanel>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconRotation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final usagePercentage = widget.userInfo.usagePercentage;

    // 根据使用百分比确定颜色
    Color getUsageColor() {
      if (usagePercentage < 50) {
        return Colors.green;
      } else if (usagePercentage < 80) {
        return Colors.orange;
      } else {
        return Colors.red;
      }
    }

    final usageColor = getUsageColor();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isDark
              ? [
                  const Color(0xFF1E3A5F).withValues(alpha: 0.4),
                  const Color(0xFF2D1B4E).withValues(alpha: 0.3),
                ]
              : [
                  const Color(0xFFE3F2FD).withValues(alpha: 0.6),
                  const Color(0xFFF3E5F5).withValues(alpha: 0.4),
                ],
        ),
        border: Border.all(
          color: widget.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 标题栏
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // 图标容器
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          usageColor.withValues(alpha: 0.2),
                          usageColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      FluentIcons.data_usage_24_filled,
                      color: usageColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 标题
                  Expanded(
                    child: Text(
                      '流量信息',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  // 展开/折叠图标
                  RotationTransition(
                    turns: _iconRotation,
                    child: Icon(
                      FluentIcons.chevron_down_24_filled,
                      color: widget.theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 可展开内容
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: TrafficChartCard(
                      userInfo: widget.userInfo,
                      t: widget.t,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
