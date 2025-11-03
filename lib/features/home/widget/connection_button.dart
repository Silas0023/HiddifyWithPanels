import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
                          color: const Color(0xFFEF4444).withOpacity(0.3),
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
      label: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => t.connection.reconnect,
        AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => t.connection.connecting,
        AsyncData(value: final status) => status.present(t),
        _ => "",
      },
      buttonColor: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => Colors.teal,
        AsyncData(value: Connected()) when delay <= 0 || delay >= 65000 => Color.fromARGB(255, 185, 176, 103),
        AsyncData(value: Connected()) => buttonTheme.connectedColor!,
        AsyncData(value: _) => buttonTheme.idleColor!,
        _ => Colors.red,
      },
      image: switch (connectionStatus) {
        AsyncData(value: Connected()) when requiresReconnect == true => Assets.images.disconnectNorouz,
        AsyncData(value: Connected()) => Assets.images.connectNorouz,
        AsyncData(value: _) => Assets.images.disconnectNorouz,
        _ => Assets.images.disconnectNorouz,
        AsyncData(value: Disconnected()) || AsyncError() => Assets.images.disconnectNorouz,
        AsyncData(value: Connected()) => Assets.images.connectNorouz,
        _ => Assets.images.disconnectNorouz,
      },
      useImage: today.day >= 19 && today.day <= 23 && today.month == 3,
    );
  }
}

class _ConnectionButton extends StatelessWidget {
  const _ConnectionButton({
    required this.onTap,
    required this.enabled,
    required this.label,
    required this.buttonColor,
    required this.image,
    required this.useImage,
  });

  final VoidCallback onTap;
  final bool enabled;
  final String label;
  final Color buttonColor;
  final AssetGenImage image;
  final bool useImage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConnected = buttonColor != Colors.red &&
                        buttonColor != Color.fromARGB(255, 185, 176, 103) &&
                        enabled;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        blurRadius: 40,
                        spreadRadius: 4,
                        color: buttonColor.withOpacity(isDark ? 0.4 : 0.25),
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        blurRadius: 20,
                        spreadRadius: -4,
                        color: buttonColor.withOpacity(isDark ? 0.3 : 0.2),
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            width: 180,
            height: 180,
            child: Material(
              key: const ValueKey("home_connection_button"),
              shape: const CircleBorder(),
              elevation: 0,
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: enabled
                        ? isConnected
                            ? [
                                buttonColor,
                                buttonColor.withOpacity(0.8),
                              ]
                            : isDark
                                ? [
                                    const Color(0xFF1E293B),
                                    const Color(0xFF0F172A),
                                  ]
                                : [
                                    Colors.white,
                                    const Color(0xFFF8FAFC),
                                  ]
                        : isDark
                            ? [
                                const Color(0xFF1E293B).withOpacity(0.5),
                                const Color(0xFF0F172A).withOpacity(0.5),
                              ]
                            : [
                                Colors.white.withOpacity(0.5),
                                const Color(0xFFF8FAFC).withOpacity(0.5),
                              ],
                  ),
                  border: Border.all(
                    color: enabled
                        ? isConnected
                            ? Colors.white.withOpacity(isDark ? 0.2 : 0.3)
                            : isDark
                                ? Colors.white.withOpacity(0.1)
                                : const Color(0xFFE2E8F0)
                        : (isDark ? Colors.white10 : Colors.black12),
                    width: 3,
                  ),
                  boxShadow: isConnected
                      ? [
                          BoxShadow(
                            color: Colors.white.withOpacity(isDark ? 0.1 : 0.2),
                            blurRadius: 12,
                            offset: const Offset(-4, -4),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                            blurRadius: 12,
                            offset: const Offset(4, 4),
                          ),
                        ]
                      : [],
                ),
                child: InkWell(
                  onTap: enabled ? onTap : null,
                  splashColor: buttonColor.withOpacity(0.2),
                  highlightColor: buttonColor.withOpacity(0.1),
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: TweenAnimationBuilder(
                      tween: ColorTween(end: buttonColor),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        if (useImage) {
                          return Padding(
                            padding: const EdgeInsets.all(36),
                            child: image.image(
                              filterQuality: FilterQuality.medium,
                              opacity: enabled ? const AlwaysStoppedAnimation(1.0) : const AlwaysStoppedAnimation(0.5),
                            ),
                          );
                        } else {
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              // 外层光晕圆环 (仅已连接状态)
                              if (isConnected) ...[
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(isDark ? 0.15 : 0.25),
                                      width: 2,
                                    ),
                                  ),
                                )
                                .animate(onPlay: (controller) => controller.repeat())
                                .scaleXY(
                                  begin: 1.0,
                                  end: 1.2,
                                  duration: 2000.ms,
                                  curve: Curves.easeInOut,
                                )
                                .fade(
                                  begin: 0.6,
                                  end: 0.0,
                                  duration: 2000.ms,
                                  curve: Curves.easeInOut,
                                ),
                              ],
                              // 主图标
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isConnected
                                      ? Colors.white.withOpacity(isDark ? 0.15 : 0.2)
                                      : Colors.transparent,
                                ),
                                child: Icon(
                                  isConnected
                                      ? FluentIcons.shield_checkmark_24_filled
                                      : FluentIcons.power_24_filled,
                                  size: 42,
                                  color: isConnected
                                      ? Colors.white
                                      : (enabled
                                          ? (isDark ? Colors.white70 : const Color(0xFF64748B))
                                          : (isDark ? Colors.white30 : Colors.black26)),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            )
            .animate(target: enabled ? 0 : 1)
            .scaleXY(end: .92, curve: Curves.easeOut)
            .then()
            .shimmer(
              duration: 2000.ms,
              color: isConnected && enabled
                  ? Colors.white.withOpacity(0.3)
                  : Colors.transparent,
            ),
          ),
        ),
        const Gap(28),
        ExcludeSemantics(
          child: AnimatedText(
            label,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: 0.5,
              color: enabled
                  ? isConnected
                      ? (isDark ? Colors.white : buttonColor)
                      : (isDark ? Colors.white : const Color(0xFF1E293B))
                  : (isDark ? Colors.white38 : Colors.black38),
            ),
          ),
        ),
      ],
    );
  }
}
