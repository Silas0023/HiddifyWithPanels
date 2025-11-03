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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标容器
              if (icon != null) ...[
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF1E3A5F).withOpacity(0.6),
                              const Color(0xFF0D2847).withOpacity(0.4),
                            ]
                          : [
                              const Color(0xFFF3F4F6),
                              const Color(0xFFE5E7EB),
                            ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? Colors.black : Colors.grey[300]!).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
                  ),
                ),
                const Gap(32),
              ],
              // 消息文本
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            const Color(0xFF1E293B).withOpacity(0.6),
                            const Color(0xFF0F172A).withOpacity(0.4),
                          ]
                        : [
                            Colors.white,
                            const Color(0xFFF8FAFC),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey[200]!,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.grey[300]!).withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
