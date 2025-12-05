import 'package:dio/dio.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/foundation.dart';
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
import 'package:hiddify/features/panel/xboard/services/subscription.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/user_info_viewmodel.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
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

    // 显示需要购买套餐的对话框
    void showPurchaseRequiredDialog() {
      if (!context.mounted) return;
      showDialog(
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
                      Color(0xFFF59E0B),
                      Color(0xFFD97706),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
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
              // 标题
              const Text(
                '需要购买套餐',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              // 描述
              const Text(
                '您当前没有可用的套餐，请购买套餐后再连接VPN',
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

    // 显示没有配置文件的对话框
    void showNoProfileDialog() {
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF4F46E5),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.3),
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
              // 标题
              const Text(
                '没有配置文件',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              // 描述
              const Text(
                '请先购买套餐获取订阅配置，然后再连接VPN',
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

    // 导入或更新配置文件并检查403错误
    Future<bool> importOrUpdateProfile() async {
      try {
        final activeProfile = await ref.read(activeProfileProvider.future);

        // 如果没有活动配置，先尝试导入订阅
        if (activeProfile == null) {
          if (kDebugMode) {
            print('[ConnectionButton] 没有活动的配置文件，尝试导入订阅...');
          }

          try {
            // 尝试导入订阅
            if (!context.mounted) return false;
            await Subscription.updateSubscription(context, ref);

            // 刷新 activeProfileProvider 以获取最新状态
            ref.invalidate(activeProfileProvider);

            // 等待一小段时间让 stream 发出新值
            await Future.delayed(const Duration(milliseconds: 500));

            // 检查导入后是否有活动配置
            final newActiveProfile = await ref.read(activeProfileProvider.future);
            if (newActiveProfile == null) {
              if (kDebugMode) {
                print('[ConnectionButton] 导入后仍然没有配置文件');
              }
              showNoProfileDialog();
              return false;
            }

            if (kDebugMode) {
              print('[ConnectionButton] 订阅导入成功: ${newActiveProfile.name}');
            }
            return true;
          } catch (importError) {
            if (kDebugMode) {
              print('[ConnectionButton] 导入订阅失败: $importError');
            }

            final errorStr = importError.toString().toLowerCase();
            if (errorStr.contains('403')) {
              showPurchaseRequiredDialog();
              return false;
            }

            // 显示没有配置文件的提示
            showNoProfileDialog();
            return false;
          }
        }

        // 已有配置，只有远程配置才需要更新
        if (activeProfile is! RemoteProfileEntity) {
          return true; // 本地配置不需要更新
        }

        if (kDebugMode) {
          print('[ConnectionButton] 开始更新配置文件: ${activeProfile.name}');
        }

        // 尝试更新订阅配置
        final profileRepository = await ref.read(profileRepositoryProvider.future);
        final result = await profileRepository.updateSubscription(activeProfile).run();

        return result.fold(
          (failure) {
            if (kDebugMode) {
              print('[ConnectionButton] 更新配置文件失败: $failure');
            }

            // 检查错误消息中是否包含403
            final errorStr = failure.toString().toLowerCase();
            if (errorStr.contains('403')) {
              if (kDebugMode) {
                print('[ConnectionButton] 错误消息包含403，需要购买套餐');
              }
              showPurchaseRequiredDialog();
              return false;
            }

            // 其他错误，继续尝试连接（可能是网络问题，但本地有配置）
            return true;
          },
          (_) {
            if (kDebugMode) {
              print('[ConnectionButton] 配置文件更新成功');
            }
            // 刷新 activeProfileProvider 以确保使用最新配置
            ref.invalidate(activeProfileProvider);
            return true;
          },
        );
      } catch (e) {
        if (kDebugMode) {
          print('[ConnectionButton] 更新配置文件异常: $e');
        }

        // 检查是否是403错误
        if (e is DioException && e.response?.statusCode == 403) {
          showPurchaseRequiredDialog();
          return false;
        }

        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('403')) {
          showPurchaseRequiredDialog();
          return false;
        }

        // 其他错误继续尝试连接
        return true;
      }
    }

    return _ConnectionButton(
      onTap: switch (connectionStatus) {
        AsyncData(value: Disconnected()) || AsyncError() => () async {
            if (kDebugMode) {
              print('[ConnectionButton] 连接按钮被点击，开始处理...');
            }
            // 检查订阅是否过期
            if (await checkSubscriptionExpired()) {
              if (kDebugMode) {
                print('[ConnectionButton] 订阅已过期，终止连接');
              }
              return;
            }
            // 导入或更新配置文件并检查403错误
            if (kDebugMode) {
              print('[ConnectionButton] 开始导入或更新配置文件...');
            }
            if (!await importOrUpdateProfile()) {
              if (kDebugMode) {
                print('[ConnectionButton] 配置文件导入/更新失败，终止连接');
              }
              return;
            }
            if (kDebugMode) {
              print('[ConnectionButton] 配置文件导入/更新成功，准备连接...');
            }
            if (await showExperimentalNotice()) {
              if (kDebugMode) {
                print('[ConnectionButton] 调用 toggleConnection()');
              }
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
      // 已连接：蓝色发光
      return const Color(0xFF0EA5E9);
    } else {
      // 未连接：深蓝色发光
      return const Color(0xFF0284C7);
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
      // 已连接：蓝色渐变
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF38BDF8), // 亮蓝色
          Color(0xFF0EA5E9), // 天蓝色
        ],
      );
    } else {
      // 未连接：深蓝色渐变
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0EA5E9), // 天蓝
          Color(0xFF0284C7), // 深蓝
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
