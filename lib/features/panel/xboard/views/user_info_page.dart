import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/app_router.dart';
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';
import 'package:hiddify/features/panel/xboard/services/subscription.dart';
import 'package:hiddify/features/panel/xboard/utils/logout_dialog.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/user_info_viewmodel.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserInfoPage extends ConsumerStatefulWidget {
  const UserInfoPage({super.key});

  @override
  ConsumerState<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends ConsumerState<UserInfoPage> {
  bool _isRefreshing = false;

  Future<void> _refreshUserInfo() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    HapticFeedback.mediumImpact();

    try {
      await ref.read(userInfoViewModelProvider.notifier).refresh();

      // 获取最新的用户信息
      final latestUserInfo = ref.read(userInfoViewModelProvider).value;
      if (latestUserInfo == null) {
        if (mounted) {
          _showSnackBar('无法获取用户信息', isError: true);
        }
        return;
      }

      // 检查是否过期
      if (latestUserInfo.isExpired) {
        if (mounted) {
          _showSnackBar('订阅已过期，请购买新套餐', isWarning: true);
        }
        return;
      }

      // 更新订阅
      final navigatorContext = rootNavigatorKey.currentContext;
      if (navigatorContext != null) {
        await Subscription.updateSubscription(navigatorContext, ref);
        if (mounted) {
          _showSnackBar('刷新成功');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('刷新失败: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false, bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.shade600
            : isWarning
                ? Colors.orange.shade600
                : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final userInfoAsync = ref.watch(userInfoViewModelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题区域
            _buildHeader(isDark, t),
            // 内容区域
            Expanded(
              child: userInfoAsync.when(
                data: (userInfo) {
                  if (userInfo == null) {
                    return _buildEmptyState(isDark);
                  }
                  return RefreshIndicator(
                    onRefresh: _refreshUserInfo,
                    color: const Color(0xFF10B981),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // 用户信息卡片
                          _buildUserCard(userInfo, isDark),
                          const SizedBox(height: 16),
                          // 流量信息卡片
                          _buildTrafficCard(userInfo, isDark),
                          const SizedBox(height: 16),
                          // 订阅信息卡片
                          _buildSubscriptionCard(userInfo, isDark, t),
                          const SizedBox(height: 24),
                          // 退出登录按钮
                          _buildLogoutButton(isDark),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => _buildLoadingState(),
                error: (error, _) => _buildErrorState(isDark, t, error.toString()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Translations t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          // 标题图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              FluentIcons.person_24_filled,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // 标题
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.userInfo.pageTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '管理您的账户信息',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // 刷新按钮
          GestureDetector(
            onTap: _isRefreshing ? null : _refreshUserInfo,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                ),
              ),
              child: _isRefreshing
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                    )
                  : const Icon(
                      FluentIcons.arrow_sync_24_regular,
                      size: 20,
                      color: Color(0xFF8B5CF6),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserInfo userInfo, bool isDark) {
    // 优先显示手机号，如果没有则显示邮箱
    final displayName = userInfo.phoneNumber?.isNotEmpty == true
        ? userInfo.phoneNumber!
        : userInfo.email;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // 头像
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: userInfo.avatarUrl.isNotEmpty
                  ? Image.network(
                      userInfo.avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        FluentIcons.person_24_filled,
                        color: Colors.white,
                        size: 28,
                      ),
                    )
                  : const Icon(
                      FluentIcons.person_24_filled,
                      color: Colors.white,
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // 用户名和状态
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // 状态标签
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: userInfo.banned
                        ? Colors.red.withValues(alpha: 0.1)
                        : const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        userInfo.banned
                            ? FluentIcons.dismiss_circle_24_filled
                            : FluentIcons.checkmark_circle_24_filled,
                        size: 14,
                        color: userInfo.banned ? Colors.red : const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        userInfo.banned ? '已禁用' : '正常',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: userInfo.banned ? Colors.red : const Color(0xFF10B981),
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
    );
  }

  Widget _buildTrafficCard(UserInfo userInfo, bool isDark) {
    final usedTraffic = userInfo.usedTraffic;
    final totalTraffic = userInfo.transferEnable;
    final usagePercent = userInfo.usagePercentage / 100;

    // 根据使用百分比确定颜色
    Color progressColor;
    if (usagePercent < 0.5) {
      progressColor = const Color(0xFF10B981);
    } else if (usagePercent < 0.8) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  FluentIcons.data_usage_24_filled,
                  color: progressColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '流量使用',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${(usagePercent * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: usagePercent.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 16),
          // 流量详情
          Row(
            children: [
              Expanded(
                child: _buildTrafficItem(
                  '已使用',
                  _formatBytes(usedTraffic),
                  FluentIcons.arrow_upload_24_regular,
                  const Color(0xFF0EA5E9),
                  isDark,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              ),
              Expanded(
                child: _buildTrafficItem(
                  '总流量',
                  _formatBytes(totalTraffic),
                  FluentIcons.database_24_regular,
                  const Color(0xFF8B5CF6),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficItem(String label, String value, IconData icon, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(UserInfo userInfo, bool isDark, Translations t) {
    final remainingDays = userInfo.remainingDays;
    final isExpired = userInfo.isExpired;
    final expireDate = userInfo.expireDate;
    final planName = userInfo.planName ?? '未知套餐';

    // 根据剩余天数确定颜色
    Color statusColor;
    String statusText;
    if (remainingDays == null) {
      statusColor = const Color(0xFF8B5CF6);
      statusText = '永久有效';
    } else if (isExpired) {
      statusColor = Colors.red;
      statusText = '已过期';
    } else if (remainingDays < 7) {
      statusColor = Colors.orange;
      statusText = '$remainingDays 天';
    } else {
      statusColor = const Color(0xFF10B981);
      statusText = '$remainingDays 天';
    }

    // 格式化过期日期
    String expireDateText = '';
    if (expireDate != null) {
      expireDateText = '${expireDate.year}-${expireDate.month.toString().padLeft(2, '0')}-${expireDate.day.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // 套餐信息
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  FluentIcons.gift_card_24_filled,
                  color: Color(0xFF0EA5E9),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前套餐',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      planName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 分隔线
          Container(
            height: 1,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          // 剩余时间
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  FluentIcons.calendar_clock_24_filled,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '剩余时间',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (expireDateText.isNotEmpty)
                      Text(
                        '到期: $expireDateText',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, statusColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (isExpired || (remainingDays != null && remainingDays < 7)) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: statusColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    FluentIcons.warning_24_filled,
                    color: statusColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isExpired ? '您的订阅已过期，请续费以继续使用' : '订阅即将到期，请及时续费',
                      style: TextStyle(
                        fontSize: 13,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoutButton(bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        showDialog(
          context: context,
          builder: (context) => const LogoutDialog(),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FluentIcons.sign_out_24_filled,
              color: Colors.red.shade400,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              '退出登录',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '加载中...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              FluentIcons.person_24_regular,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '无法加载用户信息',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, Translations t, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              FluentIcons.error_circle_24_regular,
              size: 40,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.userInfo.fetchUserInfoError,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(double bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    var value = bytes;
    while (value >= 1024 && i < suffixes.length - 1) {
      value /= 1024;
      i++;
    }
    return '${value.toStringAsFixed(2)} ${suffixes[i]}';
  }
}
