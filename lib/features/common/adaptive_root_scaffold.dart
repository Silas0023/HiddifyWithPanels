import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/notice_viewmodel.dart';
import 'package:hiddify/features/stats/widget/side_bar_stats_overview.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

abstract interface class RootScaffold {
  static final stateKey = GlobalKey<ScaffoldState>();

  static bool canShowDrawer(BuildContext context) => Breakpoints.small.isActive(context);
}

class AdaptiveRootScaffold extends HookConsumerWidget {
  const AdaptiveRootScaffold(this.navigator, {super.key});

  final Widget navigator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final noticesAsync = ref.watch(noticeViewModelProvider);
    final hasImportantNotices = noticesAsync.valueOrNull?.any((notice) => notice.tagsList.isNotEmpty) ?? false;

    final selectedIndex = getCurrentIndex(context);

    final destinations = [
      const NavigationDestination(
        icon: Icon(FluentIcons.home_24_regular),
        selectedIcon: Icon(FluentIcons.home_24_filled),
        label: '首页',
      ),
      const NavigationDestination(
        icon: Icon(FluentIcons.globe_24_regular),
        selectedIcon: Icon(FluentIcons.globe_24_filled),
        label: '区域',
      ),
      // 隐藏应用中心
      // const NavigationDestination(
      //   icon: Icon(FluentIcons.apps_24_regular),
      //   selectedIcon: Icon(FluentIcons.apps_24_filled),
      //   label: '应用中心',
      // ),
      NavigationDestination(
        icon: const Icon(FluentIcons.cart_24_regular),
        selectedIcon: const Icon(FluentIcons.cart_24_filled),
        label: t.purchase.pageTitle,
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.person_24_regular),
        selectedIcon: const Icon(FluentIcons.person_24_filled),
        label: t.userInfo.pageTitle,
      ),
      NavigationDestination(
        icon: hasImportantNotices
            ? const Badge(
                smallSize: 8,
                child: Icon(FluentIcons.alert_24_regular),
              )
            : const Icon(FluentIcons.alert_24_regular),
        selectedIcon: hasImportantNotices
            ? const Badge(
                smallSize: 8,
                child: Icon(FluentIcons.alert_24_filled),
              )
            : const Icon(FluentIcons.alert_24_filled),
        label: '通知',
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.settings_24_regular),
        selectedIcon: const Icon(FluentIcons.settings_24_filled),
        label: t.settings.pageTitle,
      ),
      NavigationDestination(
        icon: const Icon(FluentIcons.options_24_regular),
        selectedIcon: const Icon(FluentIcons.options_24_filled),
        label: t.config.pageTitle,
      ),
    ];

    return _CustomAdaptiveScaffold(
      selectedIndex: selectedIndex,
      onSelectedIndexChange: (index) {
        // 退出菜单已隐藏，不再需要检查
        // if (index == destinations.length - 1) {
        //   // 显示登出对话框
        //   showDialog(
        //     context: context,
        //     builder: (context) => const LogoutDialog(),
        //   );
        // } else {
        //   RootScaffold.stateKey.currentState?.closeDrawer();
        //   switchTab(index, context);
        // }
        RootScaffold.stateKey.currentState?.closeDrawer();
        switchTab(index, context);
      },
      destinations: destinations,
      drawerDestinationRange: useMobileRouter ? (5, null) : (0, null),
      bottomDestinationRange: (0, 5),
      useBottomSheet: useMobileRouter,
      sidebarTrailing: const Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SideBarStatsOverview(),
        ),
      ),
      body: navigator,
    );
  }
}

class _CustomAdaptiveScaffold extends HookConsumerWidget {
  const _CustomAdaptiveScaffold({
    required this.selectedIndex,
    required this.onSelectedIndexChange,
    required this.destinations,
    required this.drawerDestinationRange,
    required this.bottomDestinationRange,
    this.useBottomSheet = false,
    this.sidebarTrailing,
    required this.body,
  });

  final int selectedIndex;
  final Function(int) onSelectedIndexChange;
  final List<NavigationDestination> destinations;
  final (int, int?) drawerDestinationRange;
  final (int, int?) bottomDestinationRange;
  final bool useBottomSheet;
  final Widget? sidebarTrailing;
  final Widget body;

  List<NavigationDestination> destinationsSlice((int, int?) range) => destinations.sublist(range.$1, range.$2);

  int? selectedWithOffset((int, int?) range) {
    final index = selectedIndex - range.$1;
    return index < 0 || (range.$2 != null && index > (range.$2! - 1)) ? null : index;
  }

  void selectWithOffset(int index, (int, int?) range) => onSelectedIndexChange(index + range.$1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      key: RootScaffold.stateKey,
      drawer: Breakpoints.small.isActive(context)
          ? Drawer(
              width: (MediaQuery.sizeOf(context).width * 0.88).clamp(1, 304),
              child: NavigationRail(
                extended: true,
                selectedIndex: selectedWithOffset(drawerDestinationRange),
                destinations: destinationsSlice(drawerDestinationRange).map((dest) => AdaptiveScaffold.toRailDestination(dest)).toList(),
                onDestinationSelected: (index) => selectWithOffset(index, drawerDestinationRange),
              ),
            )
          : null,
      body: AdaptiveLayout(
        primaryNavigation: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            Breakpoints.medium: SlotLayout.from(
              key: const Key('primaryNavigation'),
              builder: (_) => AdaptiveScaffold.standardNavigationRail(
                selectedIndex: selectedIndex,
                destinations: destinations.map((dest) => AdaptiveScaffold.toRailDestination(dest)).toList(),
                onDestinationSelected: onSelectedIndexChange,
              ),
            ),
            Breakpoints.large: SlotLayout.from(
              key: const Key('primaryNavigation1'),
              builder: (_) => AdaptiveScaffold.standardNavigationRail(
                extended: true,
                selectedIndex: selectedIndex,
                destinations: destinations.map((dest) => AdaptiveScaffold.toRailDestination(dest)).toList(),
                onDestinationSelected: onSelectedIndexChange,
                trailing: sidebarTrailing,
              ),
            ),
          },
        ),
        body: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig?>{
            Breakpoints.standard: SlotLayout.from(
              key: const Key('body'),
              inAnimation: AdaptiveScaffold.fadeIn,
              outAnimation: AdaptiveScaffold.fadeOut,
              builder: (context) => body,
            ),
          },
        ),
      ),
      bottomNavigationBar: useBottomSheet && Breakpoints.small.isActive(context)
          ? _buildCustomBottomNav(context, ref)
          : null,
    );
  }

  Widget _buildCustomBottomNav(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomDests = destinationsSlice(bottomDestinationRange);
    final currentIndex = selectedWithOffset(bottomDestinationRange) ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(bottomDests.length, (index) {
              final dest = bottomDests[index];
              final isSelected = index == currentIndex;

              return Expanded(
                child: GestureDetector(
                  onTap: () => selectWithOffset(index, bottomDestinationRange),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 图标容器
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0EA5E9).withAlpha(25)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconTheme(
                            data: IconThemeData(
                              size: 24,
                              color: isSelected
                                  ? const Color(0xFF0EA5E9)
                                  : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                            ),
                            child: isSelected
                                ? (dest.selectedIcon ?? dest.icon)
                                : dest.icon,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 标签
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF0EA5E9)
                                : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
                          ),
                          child: Text(dest.label),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
