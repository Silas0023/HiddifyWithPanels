import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/common/nested_app_bar.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/home/widget/action_buttons_row.dart';
import 'package:hiddify/features/home/widget/empty_profiles_home_body.dart';
import 'package:hiddify/features/home/widget/subscription_info_card.dart';
import 'package:hiddify/features/panel/xboard/views/components/user_info/user_info_card.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hiddify/features/proxy/active/active_proxy_footer.dart';
import 'package:hiddify/utils/placeholders.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final hasAnyProfile = ref.watch(hasAnyProfileProvider);
    final activeProfile = ref.watch(activeProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF8FAFC),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomScrollView(
            slivers: [
              NestedAppBar(
                title: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: t.general.appTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const TextSpan(text: " "),
                      const WidgetSpan(
                        child: AppVersionLabel(),
                        alignment: PlaceholderAlignment.middle,
                      ),
                    ],
                  ),
                ),
                // 隐藏右上角快速设置按钮
                // actions: [
                //   IconButton(
                //     onPressed: () => const QuickSettingsRoute().push(context),
                //     icon: const Icon(FluentIcons.options_24_filled),
                //     tooltip: t.config.quickSettings,
                //   ),
                // ],
              ),
              switch (activeProfile) {
                // 如果有活跃的配置文件，显示相应的内容
                AsyncData(value: final profile?) => MultiSliver(
                    children: [
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      // 隐藏配置文件卡片
                      // ProfileTile(profile: profile, isMain: true),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                      const SliverToBoxAdapter(child: SubscriptionInfoCard()),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      const SliverToBoxAdapter(
                        child: ConnectionButton(),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      const SliverToBoxAdapter(child: ActionButtonsRow()),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),

                      const SliverToBoxAdapter(
                        child: ActiveProxyDelayIndicator(),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 48)),
                      // 隐藏底部连接信息卡片（显示"连接"标题、代理名称和IP地址）
                      // if (MediaQuery.sizeOf(context).width < 840) const SliverToBoxAdapter(child: ActiveProxyFooter()),
                    ],
                  ),
                // 修改无活跃配置文件时的提示信息
                AsyncData() => switch (hasAnyProfile) {
                    AsyncData(value: true) => const EmptyActiveProfileHomeBody(),
                    _ => MultiSliver(
                        children: [
                          const SliverToBoxAdapter(child: SizedBox(height: 8)),
                          // 用户信息卡片
                          const SliverToBoxAdapter(child: SubscriptionInfoCard()),
                          // const SliverToBoxAdapter(child: UserInfoCard()),
                          const SliverToBoxAdapter(child: SizedBox(height: 16)),
                          const SliverToBoxAdapter(
                            child: ConnectionButton(),
                          ),
                          // 无订阅提示卡片
                          // SliverToBoxAdapter(
                          //   child: Padding(
                          //     padding: const EdgeInsets.symmetric(horizontal: 16),
                          //     child: Container(
                          //       decoration: BoxDecoration(
                          //         gradient: LinearGradient(
                          //           begin: Alignment.topLeft,
                          //           end: Alignment.bottomRight,
                          //           colors: isDark ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] : [const Color(0xFFFFFFFF), const Color(0xFFF8FAFC)],
                          //         ),
                          //         borderRadius: BorderRadius.circular(16),
                          //         border: Border.all(
                          //           color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                          //         ),
                          //         boxShadow: [
                          //           BoxShadow(
                          //             color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                          //             blurRadius: 10,
                          //             offset: const Offset(0, 4),
                          //           ),
                          //         ],
                          //       ),
                          //       padding: const EdgeInsets.all(24),
                          //       child: Column(
                          //         children: [
                          //           // 图标
                          //           Container(
                          //             width: 80,
                          //             height: 80,
                          //             decoration: BoxDecoration(
                          //               gradient: LinearGradient(
                          //                 begin: Alignment.topLeft,
                          //                 end: Alignment.bottomRight,
                          //                 colors: [
                          //                   const Color(0xFF6366F1).withOpacity(0.8),
                          //                   const Color(0xFF8B5CF6).withOpacity(0.8),
                          //                 ],
                          //               ),
                          //               shape: BoxShape.circle,
                          //               boxShadow: [
                          //                 BoxShadow(
                          //                   color: const Color(0xFF6366F1).withOpacity(0.3),
                          //                   blurRadius: 20,
                          //                   offset: const Offset(0, 8),
                          //                 ),
                          //               ],
                          //             ),
                          //             child: const Icon(
                          //               FluentIcons.rocket_24_filled,
                          //               color: Colors.white,
                          //               size: 40,
                          //             ),
                          //           ),
                          //           const SizedBox(height: 20),
                          //           // 标题
                          //           Text(
                          //             '开启加速之旅',
                          //             style: TextStyle(
                          //               fontSize: 22,
                          //               fontWeight: FontWeight.bold,
                          //               color: isDark ? Colors.white : Colors.black87,
                          //             ),
                          //           ),
                          //           const SizedBox(height: 12),
                          //           // 描述
                          //           Text(
                          //             t.home.noSubscriptionMsg,
                          //             textAlign: TextAlign.center,
                          //             style: TextStyle(
                          //               fontSize: 15,
                          //               color: isDark ? Colors.grey[400] : Colors.grey[600],
                          //               height: 1.5,
                          //             ),
                          //           ),
                          //           const SizedBox(height: 24),
                          //           // 按钮
                          //           SizedBox(
                          //             width: double.infinity,
                          //             child: ElevatedButton(
                          //               onPressed: () {
                          //                 const PurchaseRoute().push(context);
                          //               },
                          //               style: ElevatedButton.styleFrom(
                          //                 backgroundColor: const Color(0xFF6366F1),
                          //                 foregroundColor: Colors.white,
                          //                 padding: const EdgeInsets.symmetric(vertical: 16),
                          //                 shape: RoundedRectangleBorder(
                          //                   borderRadius: BorderRadius.circular(12),
                          //                 ),
                          //                 elevation: 0,
                          //               ),
                          //               child: Row(
                          //                 mainAxisAlignment: MainAxisAlignment.center,
                          //                 children: [
                          //                   const Icon(FluentIcons.shopping_bag_24_filled, size: 20),
                          //                   const SizedBox(width: 8),
                          //                   Text(
                          //                     t.home.goToPurchasePage,
                          //                     style: const TextStyle(
                          //                       fontSize: 16,
                          //                       fontWeight: FontWeight.w600,
                          //                     ),
                          //                   ),
                          //                 ],
                          //               ),
                          //             ),
                          //           ),
                          //         ],
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          const SliverToBoxAdapter(child: SizedBox(height: 16)),
                          // 客服支持和更新配置按钮
                          const SliverToBoxAdapter(child: ActionButtonsRow()),
                          const SliverToBoxAdapter(child: SizedBox(height: 32)),
                        ],
                      ),
                  },
                AsyncError(:final error) => SliverErrorBodyPlaceholder(t.presentShortError(error)),
                _ => const SliverToBoxAdapter(),
              },
            ],
          ),
        ],
      ),
    );
  }
}

class AppVersionLabel extends HookConsumerWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    final version = ref.watch(appInfoProvider).requireValue.presentVersion;
    if (version.isBlank) return const SizedBox();

    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: t.about.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [
                    const Color(0xFF00B4D8),
                    const Color(0xFF0096C7),
                  ]
                : [
                    const Color(0xFF00A8E8),
                    const Color(0xFF0088C8),
                  ],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00A8E8).withOpacity(isDark ? 0.25 : 0.2),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 4,
        ),
        child: Text(
          version,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 10.5,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
