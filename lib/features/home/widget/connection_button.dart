import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hiddify/core/theme/theme_extensions.dart';
import 'package:hiddify/core/widget/animated_text.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/notifier/config_option_notifier.dart';
import 'package:hiddify/features/connection/model/connection_status.dart';
import 'package:hiddify/features/connection/notifier/connection_notifier.dart';
import 'package:hiddify/features/connection/widget/experimental_feature_notice.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/user_info_viewmodel.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/proxy/active/active_proxy_notifier.dart';
import 'package:hiddify/gen/assets.gen.dart';
import 'package:hiddify/utils/alerts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// TODO: rewrite
class ConnectionButton extends HookConsumerWidget {
  const ConnectionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final connectionStatus = ref.watch(connectionNotifierProvider);
    final activeProxy = ref.watch(activeProxyNotifierProvider);
    final delay = activeProxy.valueOrNull?.urlTestDelay ?? 0;
    final userInfoAsync = ref.watch(userInfoViewModelProvider);

    final requiresReconnect = ref.watch(configOptionNotifierProvider).valueOrNull;
    final today = DateTime.now();

    ref.listen(
      connectionNotifierProvider,
      (_, next) {
        if (next case AsyncError(:final error)) {
          CustomAlertDialog.fromErr(t.presentError(error)).show(context);
        }
        if (next case AsyncData(value: Disconnected(:final connectionFailure?))) {
          CustomAlertDialog.fromErr(t.presentError(connectionFailure)).show(context);
        }
      },
    );

    final buttonTheme = Theme.of(context).extension<ConnectionButtonTheme>()!;

    Future<bool> showExperimentalNotice() async {
      final hasExperimental = ref.read(ConfigOptions.hasExperimentalFeatures);
      final canShowNotice = !ref.read(disableExperimentalFeatureNoticeProvider);
      if (hasExperimental && canShowNotice && context.mounted) {
        return await const ExperimentalFeatureNoticeDialog().show(context) ?? false;
      }
      return true;
    }

    // 检查用户订阅是否过期
    Future<bool> checkSubscriptionExpired() async {
      final userInfo = userInfoAsync.valueOrNull;
      if (userInfo == null) return false;

      if (userInfo.isExpired) {
        // 如果当前已连接，先断开连接
        if (connectionStatus is AsyncData && connectionStatus.value is Connected) {
          await ref.read(connectionNotifierProvider.notifier).toggleConnection();
        }

        // 显示提示弹窗
        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 警告图标
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFEF4444),
                          Color(0xFFDC2626),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.3),
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
                  // 标题
                  const Text(
                    '订阅已过期',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 描述
                  const Text(
                    '您的订阅已过期，需要购买新套餐才能继续使用VPN服务',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 按钮
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
                              Text(
                                '购买套餐',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
                            foregroundColor: Colors.grey[600],
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            '取消',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
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
        return true; // 已过期
      }
      return false; // 未过期
    }

    return _ConnectionButton(
      onTap: switch (connectionStatus) {
        AsyncData(value: Disconnected()) || AsyncError() => () async {
            // 检查订阅是否过期
            if (await checkSubscriptionExpired()) {
              return;
            }
            if (await showExperimentalNotice()) {
              return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
            }
          },
        AsyncData(value: Connected()) => () async {
            // 检查订阅是否过期
            if (await checkSubscriptionExpired()) {
              return;
            }
            if (requiresReconnect == true && await showExperimentalNotice()) {
              return await ref.read(connectionNotifierProvider.notifier).reconnect(await ref.read(activeProfileProvider.future));
            }
            return await ref.read(connectionNotifierProvider.notifier).toggleConnection();
          },
        _ => () {},
      },
      enabled: switch (connectionStatus) {
        AsyncData(value: Connected()) || AsyncData(value: Disconnected()) || AsyncError() => true,
        _ => false,
      },
      isConnected: switch (connectionStatus) {
        AsyncData(value: Connected()) => true,
        _ => false,
      },
      label: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => t.connection.reconnect,
        AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => t.connection.connecting,
        AsyncData(value: final status) => status.present(t),
        _ => "",
      },
      buttonColor: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => Colors.teal,
        AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => const Color.fromARGB(255, 185, 176, 103),
        AsyncData(value: Connected()) => buttonTheme.connectedColor!,
        AsyncData(value: _) => buttonTheme.idleColor!,
        _ => Colors.red,
      },
      image: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => Assets.images.disconnectNorouz,
        AsyncData(value: Connected()) => Assets.images.connectNorouz,
        AsyncData(value: _) => Assets.images.disconnectNorouz,
        _ => Assets.images.disconnectNorouz,
      },
      useImage: today.day >= 19 && today.day <= 23 && today.month == 3,
    );
  }
}

class _ConnectionButton extends StatefulWidget {
  const _ConnectionButton({
    required this.onTap,
    required this.enabled,
    required this.isConnected,
    required this.label,
    required this.buttonColor,
    required this.image,
    required this.useImage,
  });

  final VoidCallback onTap;
  final bool enabled;
  final bool isConnected;
  final String label;
  final Color buttonColor;
  final AssetGenImage image;
  final bool useImage;

  @override
  State<_ConnectionButton> createState() => _ConnectionButtonState();
}

class _ConnectionButtonState extends State<_ConnectionButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ConnectionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 启动或停止脉冲动画
    if (widget.isConnected && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!widget.isConnected && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          enabled: widget.enabled,
          label: widget.label,
          child: GestureDetector(
            onTapDown: (_) {
              if (widget.enabled) {
                setState(() => _isPressed = true);
                HapticFeedback.mediumImpact();
              }
            },
            onTapUp: (_) {
              if (widget.enabled) {
                setState(() => _isPressed = false);
                widget.onTap();
              }
            },
            onTapCancel: () {
              if (widget.enabled) {
                setState(() => _isPressed = false);
              }
            },
            child: AnimatedScale(
              scale: _isPressed ? 0.95 : 1.0,
              duration: Duration(milliseconds: _isPressed ? 100 : 400),
              curve: _isPressed ? Curves.easeOut : Curves.elasticOut,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final pulseValue = _pulseController.value;
                  return _SplashStyleButton(
                    size: 160,
                    isConnected: widget.isConnected,
                    enabled: widget.enabled,
                    buttonColor: widget.buttonColor,
                    isDark: isDark,
                    pulseValue: pulseValue,
                    useImage: widget.useImage,
                    image: widget.image,
                  );
                },
              ),
            ),
          ),
        ),
        const Gap(24),
        ExcludeSemantics(
          child: AnimatedText(
            widget.label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: widget.enabled
                  ? (isDark ? Colors.white : const Color(0xFF1E293B))
                  : (isDark ? Colors.white38 : Colors.black38),
            ),
          ),
        ),
      ],
    );
  }
}

class _SplashStyleButton extends StatelessWidget {
  const _SplashStyleButton({
    required this.size,
    required this.isConnected,
    required this.enabled,
    required this.buttonColor,
    required this.isDark,
    required this.pulseValue,
    required this.useImage,
    required this.image,
  });

  final double size;
  final bool isConnected;
  final bool enabled;
  final Color buttonColor;
  final bool isDark;
  final double pulseValue;
  final bool useImage;
  final AssetGenImage image;

  @override
  Widget build(BuildContext context) {
    // 计算脉冲动画的透明度和模糊半径
    final pulseOpacity = isConnected ? (0.6 + (0.3 * (1 - pulseValue))) : 0.3;
    final pulseBlur = isConnected ? 35.0 + (15.0 * pulseValue) : 20.0;
    final pulseSpread = isConnected ? 8.0 + (4.0 * pulseValue) : 2.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: _buildGradient(),
        shape: BoxShape.circle,
        boxShadow: [
          // 强烈的彩色发光效果（已连接）或微弱阴影（未连接）
          BoxShadow(
            color: _getGlowColor().withValues(alpha: pulseOpacity),
            blurRadius: pulseBlur,
            spreadRadius: pulseSpread,
            offset: Offset(0, enabled ? (isConnected ? 12 : 4) : 2),
          ),
        ],
      ),
      child: Center(
        child: _buildIcon(),
      ),
    );
  }

  Color _getGlowColor() {
    if (!enabled) {
      return const Color(0xFF52525B);
    }

    if (isConnected) {
      // 已连接：紫色混合发光
      return const Color(0xFFb82bf7);
    } else {
      // 未连接：深紫色混合发光
      return const Color(0xFF8f21c3);
    }
  }

  LinearGradient _buildGradient() {
    if (!enabled) {
      // 禁用状态：优雅灰色渐变
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF52525B),
          Color(0xFF3F3F46),
        ],
      );
    }

    if (isConnected) {
      // 已连接：紫色渐变 - 亮紫到深紫
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFda22ff), // 亮紫色
          Color(0xFF9733ee), // 深紫色
        ],
      );
    } else {
      // 未连接：深色版紫色渐变
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFa81bcc), // 深亮紫
          Color(0xFF7628ba), // 更深紫
        ],
      );
    }
  }

  Widget _buildIcon() {
    if (useImage) {
      return Padding(
        padding: const EdgeInsets.all(36),
        child: image.image(
          opacity: enabled
              ? const AlwaysStoppedAnimation(1.0)
              : const AlwaysStoppedAnimation(0.5),
        ),
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: isConnected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      builder: (context, value, child) {
        // 图标切换动画
        final icon = isConnected
            ? FluentIcons.shield_checkmark_24_filled
            : FluentIcons.power_24_filled;

        // 图标颜色：已连接纯白色，未连接半透明白色
        final iconColor = enabled
            ? (isConnected ? Colors.white : Colors.white.withValues(alpha: 0.7))
            : Colors.white.withValues(alpha: 0.4);

        return Transform.scale(
          scale: 1.0 + (value * 0.1), // 连接时轻微放大
          child: Icon(
            icon,
            size: 60,
            color: iconColor,
          ),
        );
      },
    );
  }
}
