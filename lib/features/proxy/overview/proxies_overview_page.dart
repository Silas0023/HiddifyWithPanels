import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/features/proxy/overview/proxies_overview_notifier.dart';
import 'package:hiddify/features/proxy/widget/proxy_tile.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProxiesOverviewPage extends HookConsumerWidget with PresLogger {
  const ProxiesOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final asyncProxies = ref.watch(proxiesOverviewNotifierProvider);
    final notifier = ref.watch(proxiesOverviewNotifierProvider.notifier);

    final selectActiveProxyMutation = useMutation(
      initialOnFailure: (error) =>
          CustomToast.error(t.presentShortError(error)).show(context),
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部标题区域
            _buildHeader(context, isDark, t, notifier, asyncProxies),
            // 内容区域
            Expanded(
              child: _buildContent(
                context,
                isDark,
                t,
                asyncProxies,
                notifier,
                selectActiveProxyMutation,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    Translations t,
    ProxiesOverviewNotifier notifier,
    AsyncValue<List<ProxyGroupEntity>> asyncProxies,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          // 标题图标
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              FluentIcons.globe_24_filled,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // 标题
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '区域选择',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                '选择最佳节点连接',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // 测速按钮
          _buildActionButton(
            icon: FluentIcons.flash_24_regular,
            color: const Color(0xFF0EA5E9),
            onTap: () {
              HapticFeedback.mediumImpact();
              if (asyncProxies case AsyncData(value: final groups)) {
                if (groups.isNotEmpty) {
                  notifier.urlTest(groups.first.tag);
                }
              }
            },
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withAlpha(50),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: color,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isDark,
    Translations t,
    AsyncValue<List<ProxyGroupEntity>> asyncProxies,
    ProxiesOverviewNotifier notifier,
    ({AsyncMutation state, ValueChanged<Future<void>> setFuture, ValueChanged<void Function(Object error)> setOnFailure}) selectActiveProxyMutation,
  ) {
    switch (asyncProxies) {
      case AsyncData(value: final groups):
        if (groups.isEmpty) {
          return _buildEmptyState(isDark, t);
        }

        final group = groups.first;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: group.items.length,
          itemBuilder: (context, index) {
            final proxy = group.items[index];
            return ProxyTile(
              proxy,
              selected: group.selected == proxy.tag,
              onSelect: () {
                if (selectActiveProxyMutation.state.isInProgress) {
                  return;
                }
                HapticFeedback.lightImpact();
                selectActiveProxyMutation.setFuture(
                  notifier.changeProxy(group.tag, proxy.tag),
                );
              },
            );
          },
        );

      case AsyncError(:final error):
        return _buildErrorState(isDark, t, error);

      case AsyncLoading():
        return _buildLoadingState(isDark);

      default:
        return const SizedBox();
    }
  }

  Widget _buildEmptyState(bool isDark, Translations t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              FluentIcons.globe_24_regular,
              size: 40,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.proxies.emptyProxiesMsg,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, Translations t, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              FluentIcons.error_circle_24_regular,
              size: 40,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.presentShortError(error),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF0EA5E9),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '加载中...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
