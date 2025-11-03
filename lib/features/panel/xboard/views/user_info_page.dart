import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
// import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/services/future_provider.dart';
// 隐藏余额和佣金功能
// import 'package:hiddify/features/panel/xboard/views/components/user_info/account_balance_card.dart';
// 隐藏邀请码功能
// import 'package:hiddify/features/panel/xboard/views/components/user_info/invite_code_section.dart';
import 'package:hiddify/features/panel/xboard/views/components/user_info/reset_subscription_button.dart';
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
        title: Text(
          t.userInfo.pageTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
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
                  // 流量图表卡片
                  TrafficChartCard(
                    userInfo: userInfo,
                    t: t,
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
