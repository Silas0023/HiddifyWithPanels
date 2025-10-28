// views/user_info_card.dart
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/models/plan_model.dart';
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/services/future_provider.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/user_info_viewmodel.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserInfoCard extends ConsumerWidget {
  const UserInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  // 邮箱和状态
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userInfo.email,
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
                    if (remainingDays != null) ...[
                      _buildInfoRow(
                        icon: FluentIcons.calendar_clock_24_regular,
                        label: '剩余时间',
                        value: isExpired
                            ? '已过期'
                            : remainingDays == 0
                                ? '今天到期'
                                : '$remainingDays 天',
                        color: isExpired
                            ? Colors.red
                            : remainingDays < 7
                                ? Colors.orange
                                : Colors.green,
                        isDark: isDark,
                        isWarning: isExpired || remainingDays < 7,
                      ),
                    ] else ...[
                      _buildInfoRow(
                        icon: FluentIcons.calendar_clock_24_regular,
                        label: '剩余时间',
                        value: '永久有效',
                        color: Colors.purple,
                        isDark: isDark,
                      ),
                    ],
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
