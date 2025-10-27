import 'package:flutter/material.dart';
import 'package:hiddify/features/app_center/models/shortcut_item.dart';
import 'package:hiddify/features/app_center/services/app_center_service.dart';
import 'package:hiddify/features/common/nested_app_bar.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class AppCenterPage extends HookConsumerWidget {
  const AppCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shortcutsAsync = ref.watch(shortcutsProvider);
    final categoriesAsync = ref.watch(shortcutCategoriesProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          NestedAppBar(
            title: Text(
              '应用中心',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          categoriesAsync.when(
            data: (categories) {
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return _buildCategoryChip(context, isDark, category.name);
                      },
                    ),
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (err, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          shortcutsAsync.when(
            data: (shortcuts) {
              final enabledShortcuts = shortcuts.where((s) => s.isEnabled).toList()
                ..sort((a, b) => a.order.compareTo(b.order));

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _calculateCrossAxisCount(context),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: _calculateAspectRatio(context),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final shortcut = enabledShortcuts[index];
                      return _buildShortcutCard(context, isDark, shortcut);
                    },
                    childCount: enabledShortcuts.length,
                  ),
                ),
              );
            },
            loading: () => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDark ? const Color(0xFF60A5FA) : const Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '加载中...',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '加载失败',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        err.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 根据屏幕宽度计算列数
  int _calculateCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 1400) {
      return 6; // 超大屏：6列
    } else if (width >= 1200) {
      return 5; // 大屏：5列
    } else if (width >= 900) {
      return 4; // 中大屏：4列
    } else if (width >= 600) {
      return 3; // 平板：3列
    } else {
      return 2; // 手机：2列
    }
  }

  // 根据屏幕宽度计算卡片宽高比
  double _calculateAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= 1200) {
      return 0.85; // 大屏：更窄的卡片
    } else if (width >= 900) {
      return 0.9; // 中大屏
    } else if (width >= 600) {
      return 0.92; // 平板
    } else {
      return 0.95; // 手机：稍宽的卡片
    }
  }

  Widget _buildCategoryChip(BuildContext context, bool isDark, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white : const Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _buildShortcutCard(
    BuildContext context,
    bool isDark,
    ShortcutItem shortcut,
  ) {
    // 解析颜色字符串
    Color parseColor(String colorStr) {
      try {
        return Color(int.parse(colorStr.substring(1), radix: 16) + 0xFF000000);
      } catch (e) {
        return const Color(0xFF3B82F6);
      }
    }

    final color = parseColor(shortcut.color);
    final lighterColor = HSLColor.fromColor(color).withLightness(0.95).toColor();

    // 根据屏幕宽度调整尺寸
    final width = MediaQuery.of(context).size.width;
    final iconSize = width >= 1200 ? 68.0 : (width >= 600 ? 70.0 : 72.0);
    final iconFontSize = width >= 1200 ? 30.0 : (width >= 600 ? 31.0 : 32.0);
    final titleFontSize = width >= 1200 ? 15.0 : (width >= 600 ? 16.0 : 17.0);
    final descFontSize = width >= 1200 ? 12.0 : (width >= 600 ? 12.5 : 13.0);
    final cardPadding = width >= 1200 ? 14.0 : (width >= 600 ? 16.0 : 20.0);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1E293B),
                  const Color(0xFF1E293B).withOpacity(0.8),
                ]
              : [
                  Colors.white,
                  lighterColor.withOpacity(0.3),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? color.withOpacity(0.15)
              : color.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.15 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final url = Uri.parse(shortcut.link);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('无法打开链接: ${shortcut.link}'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(24),
          splashColor: color.withOpacity(0.1),
          highlightColor: color.withOpacity(0.05),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: cardPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 图标容器
                Container(
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withOpacity(0.25),
                        color.withOpacity(0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(iconSize * 0.28),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // 背景装饰圆圈
                      Positioned(
                        top: -10,
                        right: -10,
                        child: Container(
                          width: iconSize * 0.55,
                          height: iconSize * 0.55,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(isDark ? 0.05 : 0.3),
                          ),
                        ),
                      ),
                      // 字母图标
                      Center(
                        child: Text(
                          shortcut.icon.toUpperCase().substring(0, 1),
                          style: TextStyle(
                            fontSize: iconFontSize,
                            fontWeight: FontWeight.w900,
                            color: color,
                            letterSpacing: -1,
                            shadows: [
                              Shadow(
                                color: color.withOpacity(0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: cardPadding * 0.8),
                // 标题
                Text(
                  shortcut.name,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // 描述
                Text(
                  shortcut.description,
                  style: TextStyle(
                    fontSize: descFontSize,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
