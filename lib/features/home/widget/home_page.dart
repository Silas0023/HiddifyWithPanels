import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/common/nested_app_bar.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/home/widget/empty_profiles_home_body.dart';
import 'package:hiddify/features/home/widget/subscription_info_card.dart';
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
                      const SliverToBoxAdapter(child: SizedBox(height: 48)),
                      const SliverToBoxAdapter(
                        child: ConnectionButton(),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
                    _ => SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                t.home.noSubscriptionMsg,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  // 导航到套餐购买页面
                                  const PurchaseRoute().push(context);
                                },
                                child: Text(t.home.goToPurchasePage),
                              ),
                            ],
                          ),
                        ),
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
