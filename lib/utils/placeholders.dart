import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// TODO: improve
class SliverBodyPlaceholder extends HookConsumerWidget {
  const SliverBodyPlaceholder(this.children, {super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}

class SliverLoadingBodyPlaceholder extends HookConsumerWidget {
  const SliverLoadingBodyPlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [CircularProgressIndicator()],
      ),
    );
  }
}

class SliverErrorBodyPlaceholder extends HookConsumerWidget {
  const SliverErrorBodyPlaceholder(
    this.msg, {
    super.key,
    this.icon = FluentIcons.error_circle_24_regular,
  });

  final String msg;
  final IconData? icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Container(
        // 添加背景渐变
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0A0E1A),
                    const Color(0xFF1A1F35),
                  ]
                : [
                    const Color(0xFFF0F4FF),
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 装饰性图标区域
                if (icon != null) ...[
                  GestureDetector(
                    onTap: () {
                      // 点击图标跳转到连接VPN页面（首页）
                      const HomeRoute().go(context);
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 最外层装饰圆环
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  (isDark ? const Color(0xFF4F46E5) : const Color(0xFF6366F1)).withOpacity(0.05),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 1.0],
                              ),
                            ),
                          ),
                          // 第二层装饰圆环
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  (isDark ? const Color(0xFF4F46E5) : const Color(0xFF6366F1)).withOpacity(0.1),
                                  Colors.transparent,
                                ],
                                stops: const [0.2, 1.0],
                              ),
                            ),
                          ),
                          // 第三层圆环带边框
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (isDark ? const Color(0xFF4F46E5) : const Color(0xFF6366F1)).withOpacity(0.15),
                                width: 1.5,
                              ),
                            ),
                          ),
                          // 主图标容器
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        const Color(0xFF4F46E5),
                                        const Color(0xFF6366F1),
                                      ]
                                    : [
                                        const Color(0xFF6366F1),
                                        const Color(0xFF818CF8),
                                      ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark ? const Color(0xFF4F46E5) : const Color(0xFF6366F1)).withOpacity(0.4),
                                  blurRadius: 32,
                                  offset: const Offset(0, 12),
                                  spreadRadius: -4,
                                ),
                                BoxShadow(
                                  color: (isDark ? const Color(0xFF4F46E5) : const Color(0xFF6366F1)).withOpacity(0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              size: 56,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(56),
                ],
                // 消息文本容器
                Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF1E293B).withOpacity(0.8),
                              const Color(0xFF0F172A).withOpacity(0.6),
                            ]
                          : [
                              Colors.white.withOpacity(0.95),
                              Colors.white.withOpacity(0.85),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : const Color(0xFFE0E7FF),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : const Color(0xFF6366F1)).withOpacity(isDark ? 0.4 : 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: -4,
                      ),
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.grey[300]!).withOpacity(isDark ? 0.2 : 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 装饰性顶部线条
                      Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              (isDark ? const Color(0xFF4F46E5) : const Color(0xFF6366F1)).withOpacity(0.6),
                              (isDark ? const Color(0xFF6366F1) : const Color(0xFF818CF8)).withOpacity(0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const Gap(20),
                      // 消息文本
                      Text(
                        msg,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.8,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white.withOpacity(0.95)
                              : const Color(0xFF1E293B),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
