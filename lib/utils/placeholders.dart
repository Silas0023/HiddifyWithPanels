import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
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
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B).withOpacity(0.8),
                  ]
                : [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 装饰性圆圈背景
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // 外层光晕圆圈
                    if (icon != null) ...[
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              (isDark ? const Color(0xFF3B82F6) : const Color(0xFF60A5FA)).withOpacity(0.1),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 1.0],
                          ),
                        ),
                      ),
                      // 中层圆圈
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              (isDark ? const Color(0xFF3B82F6) : const Color(0xFF60A5FA)).withOpacity(0.15),
                              Colors.transparent,
                            ],
                            stops: const [0.3, 1.0],
                          ),
                        ),
                      ),
                      // 图标容器
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    const Color(0xFF1E3A5F).withOpacity(0.8),
                                    const Color(0xFF0D2847).withOpacity(0.6),
                                  ]
                                : [
                                    const Color(0xFFEFF6FF),
                                    const Color(0xFFDBEAFE),
                                  ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF60A5FA)).withOpacity(0.2),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF60A5FA)).withOpacity(0.2),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: (isDark ? Colors.black : Colors.grey[300]!).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          size: 52,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ],
                ),
                const Gap(48),
                // 消息文本容器
                Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF1E293B).withOpacity(0.7),
                              const Color(0xFF0F172A).withOpacity(0.5),
                            ]
                          : [
                              Colors.white,
                              const Color(0xFFFAFAFA),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.grey[200]!.withOpacity(0.8),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.grey[400]!).withOpacity(isDark ? 0.3 : 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                        spreadRadius: -2,
                      ),
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.grey[300]!).withOpacity(isDark ? 0.2 : 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.7,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white.withOpacity(0.92) : const Color(0xFF1E293B),
                      letterSpacing: 0.3,
                    ),
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
