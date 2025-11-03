import 'dart:math' as math;

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
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SubscriptionInfoCard extends ConsumerStatefulWidget {
  const SubscriptionInfoCard({super.key});

  @override
  ConsumerState<SubscriptionInfoCard> createState() => _SubscriptionInfoCardState();
}

class _SubscriptionInfoCardState extends ConsumerState<SubscriptionInfoCard> {
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
            print('========== [SubscriptionInfoCard-StateError] Widget Disposed 错误（已忽略） ==========');
            print('错误类型: ${e.runtimeType}');
            print('错误信息: $e');
            print('是否包含 "ref": ${errorMsg.contains('ref')}');
            print('是否包含 "disposed": ${errorMsg.contains('disposed')}');
            print('========================================');
          } else {
            print('========== [SubscriptionInfoCard-StateError] 订阅更新错误 ==========');
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
      final isDisposedError = errorMsg.contains('disposed') || errorMsg.contains('bad state') || (errorMsg.contains('cannot use') && errorMsg.contains('ref'));

      if (kDebugMode) {
        if (isDisposedError) {
          print('========== [SubscriptionInfoCard] Widget Disposed 错误（已忽略） ==========');
          print('错误类型: ${e.runtimeType}');
          print('错误信息: $e');
          print('是否包含 "disposed": ${errorMsg.contains('disposed')}');
          print('是否包含 "bad state": ${errorMsg.contains('bad state')}');
          print('是否包含 "cannot use" + "ref": ${errorMsg.contains('cannot use') && errorMsg.contains('ref')}');
          print('========================================');
        } else {
          print('========== [SubscriptionInfoCard] 刷新订阅配置错误 ==========');
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

  String _formatBytes(double bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (math.log(bytes) / math.log(1024)).floor();
    final value = bytes / math.pow(1024, i);
    return '${value.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final userInfoAsync = ref.watch(userInfoViewModelProvider);
    final plansAsync = ref.watch(plansProvider);
    final activeProfileAsync = ref.watch(activeProfileProvider);
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return userInfoAsync.when(
      data: (userInfo) {
        if (userInfo == null) return const SizedBox.shrink();

        return plansAsync.when(
          data: (plans) => _buildCard(context, userInfo, plans, activeProfileAsync, t, theme, isDark),
          loading: () => _buildLoadingCard(theme, isDark),
          error: (_, __) => _buildCard(context, userInfo, [], activeProfileAsync, t, theme, isDark),
        );
      },
      loading: () => _buildLoadingCard(theme, isDark),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildLoadingCard(ThemeData theme, bool isDark) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 120,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    UserInfo userInfo,
    List<Plan> plans,
    AsyncValue<ProfileEntity?> activeProfileAsync,
    Translations t,
    ThemeData theme,
    bool isDark,
  ) {
    // 查找套餐名称
    String planName = '套餐 #${userInfo.planId}';
    try {
      final plan = plans.firstWhere((p) => p.id == userInfo.planId);
      planName = plan.name;
    } catch (e) {
      planName = '套餐 #${userInfo.planId}';
    }

    // 检查当前是否有激活的远程订阅配置
    bool isActiveProfile = false;
    activeProfileAsync.whenData((activeProfile) {
      if (activeProfile != null && activeProfile is RemoteProfileEntity) {
        // 有远程订阅配置被激活
        isActiveProfile = true;
      }
    });

    final usagePercentage = userInfo.usagePercentage;
    final remainingDays = userInfo.remainingDays;
    final isExpired = userInfo.isExpired;

    // 确定流量使用颜色
    Color getUsageColor() {
      if (usagePercentage < 50) return Colors.green;
      if (usagePercentage < 80) return Colors.orange;
      return Colors.red;
    }

    // 确定剩余天数颜色
    Color getExpiryColor() {
      if (isExpired) return Colors.red;
      if (remainingDays != null && remainingDays < 7) return Colors.orange;
      return Colors.green;
    }

    final usageColor = getUsageColor();
    final expiryColor = getExpiryColor();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              theme.colorScheme.secondaryContainer.withValues(alpha: 0.2),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 用户邮箱和刷新按钮
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      FluentIcons.person_24_filled,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      userInfo.email,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // 激活状态指示器
                  if (isActiveProfile) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green, width: 1.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FluentIcons.checkmark_circle_24_filled,
                            color: Colors.green,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '连接配置已激活',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FluentIcons.circle_24_regular,
                            color: Colors.grey[600],
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '连接配置未激活',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // 刷新按钮
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      icon: _isRefreshing
                          ? SizedBox(
                              width: 18,
                              height: 18,
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
                              size: 18,
                            ),
                      onPressed: _isRefreshing ? null : () => _handleRefresh(context, userInfo),
                      tooltip: '刷新订阅',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 套餐信息行
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      FluentIcons.cube_24_filled,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          planName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (userInfo.expiredAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            '到期: ${_formatDate(userInfo.expiredAt!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 剩余天数标签
                  if (remainingDays != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: expiryColor.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: expiryColor),
                      ),
                      child: Text(
                        isExpired
                            ? '已过期'
                            : remainingDays == 0
                                ? '今天到期'
                                : '$remainingDays 天',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: expiryColor,
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple),
                      ),
                      child: const Text(
                        '永久',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // 流量使用折叠面板
              _TrafficCollapsibleSection(
                userInfo: userInfo,
                usageColor: usageColor,
                isDark: isDark,
                formatBytes: _formatBytes,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 流量使用折叠面板
class _TrafficCollapsibleSection extends StatefulWidget {
  final UserInfo userInfo;
  final Color usageColor;
  final bool isDark;
  final String Function(double) formatBytes;

  const _TrafficCollapsibleSection({
    required this.userInfo,
    required this.usageColor,
    required this.isDark,
    required this.formatBytes,
  });

  @override
  State<_TrafficCollapsibleSection> createState() =>
      _TrafficCollapsibleSectionState();
}

class _TrafficCollapsibleSectionState extends State<_TrafficCollapsibleSection>
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

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.grey[850]!.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          // 标题栏
          InkWell(
            onTap: _toggleExpansion,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 流量图标
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.usageColor.withValues(alpha: 0.2),
                          widget.usageColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      FluentIcons.data_usage_24_filled,
                      color: widget.usageColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 标题
                  Expanded(
                    child: Text(
                      '流量使用',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ),
                  // 展开/折叠图标
                  RotationTransition(
                    turns: _iconRotation,
                    child: Icon(
                      FluentIcons.chevron_down_24_filled,
                      color: widget.usageColor,
                      size: 20,
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
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 进度条和百分比
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '使用进度',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: widget.isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                            Text(
                              '${usagePercentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: widget.usageColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: usagePercentage / 100,
                            minHeight: 8,
                            backgroundColor: widget.isDark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.usageColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // 流量详细信息
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTrafficInfo(
                              icon: FluentIcons.arrow_upload_16_regular,
                              label: '已用',
                              value: widget.formatBytes(widget.userInfo.usedTraffic),
                            ),
                            _buildTrafficInfo(
                              icon: FluentIcons.database_16_regular,
                              label: '总计',
                              value: widget.formatBytes(widget.userInfo.transferEnable),
                            ),
                            _buildTrafficInfo(
                              icon: FluentIcons.storage_16_regular,
                              label: '剩余',
                              value: widget.formatBytes(widget.userInfo.remainingTraffic),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficInfo({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: widget.usageColor,
          size: 16,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: widget.isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
