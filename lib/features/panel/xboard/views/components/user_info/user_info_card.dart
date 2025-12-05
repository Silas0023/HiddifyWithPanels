// views/user_info_card.dart
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/app_router.dart';
import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/services/future_provider.dart';
import 'package:hiddify/features/panel/xboard/services/subscription.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/user_info_viewmodel.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserInfoCard extends ConsumerStatefulWidget {
  const UserInfoCard({super.key});

  @override
  ConsumerState<UserInfoCard> createState() => _UserInfoCardState();
}

class _UserInfoCardState extends ConsumerState<UserInfoCard> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh(BuildContext context, UserInfo oldUserInfo) async {
    if (_isRefreshing) return;

    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // 先刷新用户信息，获取最新数据
      if (kDebugMode) {
        print('[UserInfoCard] 开始刷新用户信息...');
      }

      // 在异步操作前保存 notifier 引用
      final userInfoNotifier = ref.read(userInfoViewModelProvider.notifier);
      await userInfoNotifier.refresh();

      // 检查 widget 是否还存在
      if (!mounted) return;

      // 获取最新的用户信息
      final latestUserInfo = ref.read(userInfoViewModelProvider).value;

      if (latestUserInfo == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法获取用户信息'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 检查最新的用户是否过期
      if (latestUserInfo.isExpired) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('订阅已过期，请购买新套餐'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 使用全局 context 进行订阅更新
      final navigatorContext = rootNavigatorKey.currentContext;
      if (navigatorContext == null) {
        if (kDebugMode) {
          print('[UserInfoCard] 无法获取有效的 context');
        }
        return;
      }

      if (kDebugMode) {
        print('[UserInfoCard] 开始刷新订阅配置...');
      }

      // 检查 widget 是否还存在
      if (!mounted) return;

      // 更新订阅（会获取新订阅链接、删除旧订阅、添加新订阅并设置为 activeProfile）
      try {
        await Subscription.updateSubscription(navigatorContext, ref);

        if (kDebugMode) {
          print('[UserInfoCard] 订阅配置更新完成');
        }

        // 不显示成功提示，因为刷新按钮主要用于重新激活订阅配置
        // 用户可以直接去首页查看是否激活成功
      } on StateError catch (e, stackTrace) {
        // 如果是 ref disposed 错误，直接忽略（widget 已被销毁）
        final errorMsg = e.toString().toLowerCase();
        final isDisposedError = errorMsg.contains('ref') || errorMsg.contains('disposed');

        if (kDebugMode) {
          if (isDisposedError) {
            print('========== [UserInfoCard-StateError] Widget Disposed 错误（已忽略） ==========');
            print('错误类型: ${e.runtimeType}');
            print('错误信息: $e');
            print('是否包含 "ref": ${errorMsg.contains('ref')}');
            print('是否包含 "disposed": ${errorMsg.contains('disposed')}');
            print('========================================');
          } else {
            print('========== [UserInfoCard-StateError] 订阅更新错误 ==========');
            print('错误类型: ${e.runtimeType}');
            print('错误信息: $e');
            print('堆栈跟踪:');
            print(stackTrace);
            print('========================================');
          }
        }

        if (isDisposedError) {
          return;
        }
        // 其他 StateError 重新抛出
        rethrow;
      }

    } catch (e, stackTrace) {
      // 检查是否是 widget disposed 错误
      final errorMsg = e.toString().toLowerCase();
      final isDisposedError = errorMsg.contains('disposed') ||
                              errorMsg.contains('bad state') ||
                              (errorMsg.contains('cannot use') && errorMsg.contains('ref'));

      if (kDebugMode) {
        if (isDisposedError) {
          print('========== [UserInfoCard] Widget Disposed 错误（已忽略） ==========');
          print('错误类型: ${e.runtimeType}');
          print('错误信息: $e');
          print('是否包含 "disposed": ${errorMsg.contains('disposed')}');
          print('是否包含 "bad state": ${errorMsg.contains('bad state')}');
          print('是否包含 "cannot use" + "ref": ${errorMsg.contains('cannot use') && errorMsg.contains('ref')}');
          print('========================================');
        } else {
          print('========== [UserInfoCard] 刷新订阅配置错误 ==========');
          print('错误类型: ${e.runtimeType}');
          print('错误信息: $e');
          print('堆栈跟踪:');
          print(stackTrace);
          print('========================================');
        }
      }

      // 只有在不是 disposed 错误且 widget 仍然存在时才显示错误提示
      if (mounted && !isDisposedError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userInfoAsync = ref.watch(userInfoViewModelProvider);
    final plansAsync = ref.watch(plansProvider);
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    return userInfoAsync.when(
      data: (userInfo) {
        if (userInfo == null) {
          return const SizedBox(); // 如果没有数据,则返回空占位
        }
        return plansAsync.when(
          data: (plans) => _buildUserInfoCard(userInfo, plans, t, theme, ref),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildUserInfoCard(userInfo, [], t, theme, ref),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => const SizedBox(),
    );
  }

  Widget _buildUserInfoCard(
    UserInfo userInfo,
    List<Plan> plans,
    Translations t,
    ThemeData theme,
    WidgetRef ref,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final remainingDays = userInfo.remainingDays;
    final isExpired = userInfo.isExpired;

    // 查找对应的套餐名称
    String planName = '套餐 #${userInfo.planId}';
    try {
      final plan = plans.firstWhere(
        (plan) => plan.id == userInfo.planId,
      );
      planName = plan.name;
    } catch (e) {
      // 如果找不到对应的套餐,使用默认值
      planName = '套餐 #${userInfo.planId}';
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 头像和基本信息
              Row(
                children: [
                  // 头像
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundImage: NetworkImage(userInfo.avatarUrl),
                      backgroundColor: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 手机号/邮箱和状态
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userInfo.phoneNumber?.isNotEmpty == true
                              ? userInfo.phoneNumber!
                              : userInfo.email,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // 账户状态
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: userInfo.banned
                                ? Colors.red.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: userInfo.banned
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                userInfo.banned
                                    ? FluentIcons.shield_error_24_filled
                                    : FluentIcons.checkmark_circle_24_filled,
                                size: 14,
                                color: userInfo.banned
                                    ? Colors.red
                                    : Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                userInfo.banned
                                    ? t.userInfo.banned
                                    : t.userInfo.active,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: userInfo.banned
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 刷新按钮
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: _isRefreshing
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            )
                          : Icon(
                              FluentIcons.arrow_sync_24_regular,
                              color: theme.colorScheme.primary,
                            ),
                      onPressed: _isRefreshing
                          ? null
                          : () => _handleRefresh(context, userInfo),
                      tooltip: '刷新订阅',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 套餐和过期信息
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  children: [
                    // 套餐信息
                    _buildInfoRow(
                      icon: FluentIcons.cube_24_regular,
                      label: '当前套餐',
                      value: planName,
                      color: theme.colorScheme.primary,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    // 过期时间
                    _buildInfoRow(
                      icon: FluentIcons.calendar_clock_24_regular,
                      label: '剩余时间',
                      value: remainingDays == null
                          ? '永久有效'
                          : userInfo.remainingTimeText,
                      color: remainingDays == null
                          ? Colors.purple
                          : isExpired
                              ? Colors.red
                              : remainingDays < 7
                                  ? Colors.orange
                                  : Colors.green,
                      isDark: isDark,
                      isWarning: remainingDays != null && (isExpired || remainingDays < 7),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    bool isWarning = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: isWarning ? Border.all(color: color) : null,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
