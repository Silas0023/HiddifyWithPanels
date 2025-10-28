import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/services/future_provider.dart';
import 'package:hiddify/features/panel/xboard/views/components/user_info/account_balance_card.dart';
import 'package:hiddify/features/panel/xboard/views/components/user_info/invite_code_section.dart';
import 'package:hiddify/features/panel/xboard/views/components/user_info/reset_subscription_button.dart';
import 'package:hiddify/features/panel/xboard/views/components/user_info/user_info_card.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserInfoPage extends ConsumerStatefulWidget {
  const UserInfoPage({super.key});

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends ConsumerState<UserInfoPage> {
  @override
  void initState() {
    super.initState();
    // 页面加载时自动刷新数据
    _refreshData();
  }

  void _refreshData() {
    // 刷新用户信息和邀请码列表
    // ignore: unused_result
    ref.refresh(userTokenInfoProvider);
    // ignore: unused_result
    ref.refresh(inviteCodesProvider);
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
        // 等待所有需要的数据加载完毕再渲染视图
        future: Future.wait([
          ref.watch(userTokenInfoProvider.future),
          ref.watch(inviteCodesProvider.future),
        ]),
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
                    t.general.addToClipboard,
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
          return RefreshIndicator(
            onRefresh: () async {
              _refreshData();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: const SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserInfoCard(),
                  SizedBox(height: 16),
                  AccountBalanceCard(),
                  SizedBox(height: 16),
                  InviteCodeSection(),
                  SizedBox(height: 16),
                  ResetSubscriptionButton(),
                  SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
