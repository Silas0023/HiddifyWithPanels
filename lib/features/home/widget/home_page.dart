import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/customer_support/intercom_service.dart';
import 'package:hiddify/features/panel/xboard/services/subscription.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/user_info_viewmodel.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final activeProfile = ref.watch(activeProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: switch (activeProfile) {
          AsyncData() => _HomeContent(isDark: isDark),
          AsyncError(:final error) => Center(
              child: Text(t.presentShortError(error)),
            ),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ),
    );
  }
}

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent({required this.isDark});
  final bool isDark;

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _handleRefreshUserInfo() async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);

    try {
      await ref.read(userInfoViewModelProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('用户信息已刷新'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('刷新失败: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  // 处理连接按钮点击
  Future<void> _handleConnectionTap() async {
    if (kDebugMode) {
      print('[HomePage] 连接按钮被点击，开始处理...');
    }

    final connectionStatus = ref.read(connectionNotifierProvider);
    final isConnected = connectionStatus is AsyncData && connectionStatus.value is Connected;

    // 如果已连接，直接断开
    if (isConnected) {
      if (kDebugMode) {
        print('[HomePage] 已连接状态，执行断开连接');
      }
      await ref.read(connectionNotifierProvider.notifier).toggleConnection();
      return;
    }

    // 检查订阅是否过期
    if (await _checkSubscriptionExpired()) {
      if (kDebugMode) {
        print('[HomePage] 订阅已过期，终止连接');
      }
      return;
    }

    // 导入或更新配置文件
    if (kDebugMode) {
      print('[HomePage] 开始导入或更新配置文件...');
    }
    if (!await _importOrUpdateProfile()) {
      if (kDebugMode) {
        print('[HomePage] 配置文件导入/更新失败，终止连接');
      }
      return;
    }

    // 执行连接
    if (kDebugMode) {
      print('[HomePage] 配置文件导入/更新成功，执行连接');
    }
    await ref.read(connectionNotifierProvider.notifier).toggleConnection();
  }

  // 检查订阅是否过期
  Future<bool> _checkSubscriptionExpired() async {
    final userInfoAsync = ref.read(userInfoViewModelProvider);
    final userInfo = userInfoAsync.valueOrNull;
    if (userInfo == null) return false;

    if (userInfo.isExpired) {
      final isDark = widget.isDark;
      // 显示过期提示弹窗
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withAlpha(76),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    FluentIcons.warning_24_filled,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '订阅已过期',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '您的订阅已过期，需要购买新套餐才能继续使用VPN服务',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.grey.shade400 : Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          const PurchaseRoute().push(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(FluentIcons.shopping_bag_24_filled, size: 20),
                            SizedBox(width: 8),
                            Text('购买套餐', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '取消',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
      return true;
    }
    return false;
  }

  // 显示需要购买套餐的对话框
  void _showPurchaseRequiredDialog() {
    if (!mounted) return;
    final isDark = widget.isDark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withAlpha(76),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                FluentIcons.shopping_bag_24_filled,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '需要购买套餐',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '您当前没有可用的套餐，请购买套餐后再连接VPN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey.shade400 : Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      const PurchaseRoute().push(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FluentIcons.shopping_bag_24_filled, size: 20),
                        SizedBox(width: 8),
                        Text('购买套餐', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 显示没有配置文件的对话框
  void _showNoProfileDialog() {
    if (!mounted) return;
    final isDark = widget.isDark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withAlpha(76),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                FluentIcons.document_arrow_down_24_filled,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '没有配置文件',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '请先购买套餐获取订阅配置，然后再连接VPN',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey.shade400 : Colors.black54,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      const PurchaseRoute().push(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FluentIcons.shopping_bag_24_filled, size: 20),
                        SizedBox(width: 8),
                        Text('购买套餐', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '取消',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 导入或更新配置文件
  Future<bool> _importOrUpdateProfile() async {
    try {
      final activeProfile = await ref.read(activeProfileProvider.future);

      // 如果没有活动配置，先尝试导入订阅
      if (activeProfile == null) {
        if (kDebugMode) {
          print('[HomePage] 没有活动的配置文件，尝试导入订阅...');
        }

        try {
          if (!mounted) return false;
          await Subscription.updateSubscription(context, ref);

          // 刷新 activeProfileProvider 以获取最新状态
          ref.invalidate(activeProfileProvider);

          // 等待一小段时间让 stream 发出新值
          await Future.delayed(const Duration(milliseconds: 500));

          // 检查导入后是否有活动配置
          final newActiveProfile = await ref.read(activeProfileProvider.future);
          if (newActiveProfile == null) {
            if (kDebugMode) {
              print('[HomePage] 导入后仍然没有配置文件');
            }
            _showNoProfileDialog();
            return false;
          }

          if (kDebugMode) {
            print('[HomePage] 订阅导入成功: ${newActiveProfile.name}');
          }
          return true;
        } catch (importError) {
          if (kDebugMode) {
            print('[HomePage] 导入订阅失败: $importError');
          }

          final errorStr = importError.toString().toLowerCase();
          if (errorStr.contains('403')) {
            _showPurchaseRequiredDialog();
            return false;
          }

          _showNoProfileDialog();
          return false;
        }
      }

      // 已有配置，只有远程配置才需要更新
      if (activeProfile is! RemoteProfileEntity) {
        return true; // 本地配置不需要更新
      }

      if (kDebugMode) {
        print('[HomePage] 开始更新配置文件: ${activeProfile.name}');
      }

      // 尝试更新订阅配置
      final profileRepository = await ref.read(profileRepositoryProvider.future);
      final result = await profileRepository.updateSubscription(activeProfile).run();

      return result.fold(
        (failure) {
          if (kDebugMode) {
            print('[HomePage] 更新配置文件失败: $failure');
          }

          final errorStr = failure.toString().toLowerCase();
          if (errorStr.contains('403')) {
            if (kDebugMode) {
              print('[HomePage] 错误消息包含403，需要购买套餐');
            }
            _showPurchaseRequiredDialog();
            return false;
          }

          // 其他错误，继续尝试连接
          return true;
        },
        (_) {
          if (kDebugMode) {
            print('[HomePage] 配置文件更新成功');
          }
          ref.invalidate(activeProfileProvider);
          return true;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('[HomePage] 更新配置文件异常: $e');
      }

      if (e is DioException && e.response?.statusCode == 403) {
        _showPurchaseRequiredDialog();
        return false;
      }

      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('403')) {
        _showPurchaseRequiredDialog();
        return false;
      }

      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final userInfoAsync = ref.watch(userInfoViewModelProvider);
    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final delay = activeProxy.valueOrNull?.urlTestDelay ?? 0;

    final isConnected = connectionStatus is AsyncData && connectionStatus.value is Connected;
    final isConnecting = connectionStatus is AsyncLoading;

    // 控制动画
    if (isConnected && !_pulseController.isAnimating) {
      _pulseController.repeat();
      _rotationController.repeat();
    } else if (!isConnected && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
      _rotationController.stop();
      _rotationController.reset();
    }

    // 连接中时播放旋转动画
    if (isConnecting && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!isConnecting && !isConnected && _rotationController.isAnimating) {
      _rotationController.stop();
      _rotationController.reset();
    }

    return Column(
      children: [
        // 顶部区域
        _buildHeader(userInfoAsync),

        // 中间连接按钮区域
        Expanded(
          child: Center(
            child: _buildConnectionArea(connectionStatus, isConnected, isConnecting, delay),
          ),
        ),

        // 底部快捷操作区域
        _buildBottomActions(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildHeader(AsyncValue userInfoAsync) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // 标题
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '小火箭',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              userInfoAsync.when(
                data: (userInfo) {
                  if (userInfo == null) return const SizedBox.shrink();
                  final days = userInfo.remainingDays;
                  return Text(
                    days != null ? '剩余 $days 天' : '永久会员',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const Spacer(),
          // 购买按钮
          _buildIconButton(
            icon: FluentIcons.shopping_bag_24_regular,
            onTap: () => const PurchaseRoute().push(context),
          ),
          const SizedBox(width: 8),
          // 设置按钮（下拉菜单）
          _buildSettingsDropdown(),
        ],
      ),
    );
  }

  Widget _buildSettingsDropdown() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: widget.isDark ? const Color(0xFF1A1A1A) : Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withAlpha(40),
      onSelected: (value) {
        switch (value) {
          case 'settings':
            const SettingsRoute().push(context);
          case 'advanced':
            const ConfigOptionsRoute().push(context);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'settings',
          child: Row(
            children: [
              Icon(
                FluentIcons.settings_24_regular,
                size: 20,
                color: widget.isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
              const SizedBox(width: 12),
              Text(
                '设置',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'advanced',
          child: Row(
            children: [
              Icon(
                FluentIcons.options_24_regular,
                size: 20,
                color: widget.isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
              const SizedBox(width: 12),
              Text(
                '高级设置',
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          FluentIcons.settings_24_regular,
          size: 20,
          color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildConnectionArea(
    AsyncValue connectionStatus,
    bool isConnected,
    bool isConnecting,
    int delay,
  ) {
    final primaryColor = isConnected
        ? const Color(0xFF10B981)
        : const Color(0xFF0EA5E9);
    final secondaryColor = isConnected
        ? const Color(0xFF059669)
        : const Color(0xFF0284C7);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 连接按钮组合
        GestureDetector(
          onTapDown: (_) => _scaleController.reverse(),
          onTapUp: (_) {
            _scaleController.forward();
            HapticFeedback.mediumImpact();
            _handleConnectionTap();
          },
          onTapCancel: () => _scaleController.forward(),
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulseController, _rotationController, _scaleController]),
            builder: (context, child) {
              final pulseValue = _pulseController.value;
              final rotationValue = _rotationController.value;
              final scaleValue = _scaleController.value;

              return Transform.scale(
                scale: scaleValue,
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 最外层脉冲光环（仅连接时显示）
                      if (isConnected)
                        Container(
                          width: 220 + (20 * pulseValue),
                          height: 220 + (20 * pulseValue),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withAlpha((60 * (1 - pulseValue)).toInt()),
                              width: 2,
                            ),
                          ),
                        ),

                      // 外圈旋转环
                      Transform.rotate(
                        angle: rotationValue * 2 * math.pi,
                        child: CustomPaint(
                          size: const Size(200, 200),
                          painter: _RingPainter(
                            color: primaryColor,
                            isConnected: isConnected,
                            isConnecting: isConnecting,
                            progress: isConnecting ? rotationValue : (isConnected ? 1.0 : 0.0),
                          ),
                        ),
                      ),

                      // 中间装饰环
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                        ),
                      ),

                      // 主按钮
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [primaryColor, secondaryColor],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withAlpha(isConnected ? 100 : 60),
                              blurRadius: isConnected ? 30 + (10 * pulseValue) : 20,
                              spreadRadius: isConnected ? 2 + (3 * pulseValue) : 0,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isConnecting
                                  ? FluentIcons.arrow_sync_24_filled
                                  : isConnected
                                      ? FluentIcons.shield_checkmark_24_filled
                                      : FluentIcons.power_24_filled,
                              size: 48,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isConnecting
                                  ? '连接中'
                                  : isConnected
                                      ? '已保护'
                                      : '点击连接',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // 状态信息卡片
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isConnected
                  ? primaryColor.withAlpha(50)
                  : (widget.isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(widget.isDark ? 30 : 10),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 状态指示点
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnecting
                      ? Colors.orange
                      : isConnected
                          ? const Color(0xFF10B981)
                          : Colors.grey.shade400,
                  boxShadow: isConnected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withAlpha(100),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              // 状态文字
              Text(
                isConnecting
                    ? '正在建立安全连接...'
                    : isConnected
                        ? '网络已加密保护'
                        : '点击上方按钮开始保护',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
              // 延迟显示
              if (isConnected && delay > 0 && delay < 65000) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (delay < 200
                            ? Colors.green
                            : delay < 500
                                ? Colors.orange
                                : Colors.red)
                        .withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${delay}ms',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: delay < 200
                          ? Colors.green.shade700
                          : delay < 500
                              ? Colors.orange.shade700
                              : Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // 在线客服
          Expanded(
            child: _buildActionCard(
              icon: FluentIcons.chat_help_24_filled,
              title: '在线客服',
              color: const Color(0xFF0EA5E9),
              onTap: () => IntercomService.displayMessenger(),
            ),
          ),
          const SizedBox(width: 12),
          // 刷新用户信息
          Expanded(
            child: _buildActionCard(
              icon: FluentIcons.person_sync_24_filled,
              title: '刷新信息',
              color: const Color(0xFF10B981),
              onTap: _handleRefreshUserInfo,
              isLoading: _isUpdating,
            ),
          ),
          const SizedBox(width: 12),
          // 区域选择
          Expanded(
            child: _buildActionCard(
              icon: FluentIcons.globe_24_filled,
              title: '选择区域',
              color: const Color(0xFF8B5CF6),
              onTap: () => const ProxiesRoute().push(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      ),
                    )
                  : Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: widget.isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 自定义环形画笔
class _RingPainter extends CustomPainter {
  final Color color;
  final bool isConnected;
  final bool isConnecting;
  final double progress;

  _RingPainter({
    required this.color,
    required this.isConnected,
    required this.isConnecting,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 背景环
    final bgPaint = Paint()
      ..color = color.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    if (isConnecting) {
      // 连接中：绘制旋转的弧线
      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, -math.pi / 2, math.pi * 0.7, false, arcPaint);
    } else if (isConnected) {
      // 已连接：绘制完整的彩色环，带渐变效果
      final gradientPaint = Paint()
        ..shader = SweepGradient(
          colors: [
            color.withAlpha(100),
            color,
            color.withAlpha(100),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawCircle(center, radius, gradientPaint);

      // 绘制几个装饰点
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      for (var i = 0; i < 4; i++) {
        final angle = (i * math.pi / 2) - math.pi / 2;
        final dotCenter = Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        );
        canvas.drawCircle(dotCenter, 4, dotPaint);
      }
    } else {
      // 未连接：绘制虚线环效果
      final dashPaint = Paint()
        ..color = color.withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      const dashCount = 24;
      const dashAngle = (2 * math.pi) / dashCount;
      const gapAngle = dashAngle * 0.4;
      const sweepAngle = dashAngle - gapAngle;
      final rect = Rect.fromCircle(center: center, radius: radius);

      for (var i = 0; i < dashCount; i++) {
        final startAngle = i * dashAngle;
        canvas.drawArc(rect, startAngle, sweepAngle, false, dashPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isConnected != isConnected ||
        oldDelegate.isConnecting != isConnecting ||
        oldDelegate.progress != progress;
  }
}
