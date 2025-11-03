import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/features/common/nested_app_bar.dart';
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
    final sortBy = ref.watch(proxiesSortNotifierProvider);

    final selectActiveProxyMutation = useMutation(
      initialOnFailure: (error) =>
          CustomToast.error(t.presentShortError(error)).show(context),
    );

    final appBar = NestedAppBar(
      title: Text(
        t.proxies.pageTitle,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      actions: [
        PopupMenuButton<ProxiesSort>(
          initialValue: sortBy,
          onSelected: ref.read(proxiesSortNotifierProvider.notifier).update,
          icon: const Icon(FluentIcons.arrow_sort_24_regular),
          tooltip: t.proxies.sortTooltip,
          itemBuilder: (context) {
            return [
              ...ProxiesSort.values.map(
                (e) => PopupMenuItem(
                  value: e,
                  child: Text(e.present(t)),
                ),
              ),
            ];
          },
        ),
      ],
    );

    switch (asyncProxies) {
      case AsyncData(value: final groups):
        if (groups.isEmpty) {
          return Scaffold(
            body: CustomScrollView(
              slivers: [
                appBar,
                SliverFillRemaining(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(t.proxies.emptyProxiesMsg),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        final group = groups.first;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF8FAFC),
          body: CustomScrollView(
            slivers: [
              appBar,
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  if (!PlatformUtils.isDesktop && width < 648) {
                    return SliverPadding(
                      padding: const EdgeInsets.only(top: 8, bottom: 86),
                      sliver: SliverList.builder(
                        itemBuilder: (_, index) {
                          final proxy = group.items[index];
                          return ProxyTile(
                            proxy,
                            selected: group.selected == proxy.tag,
                            onSelect: () async {
                              if (selectActiveProxyMutation
                                  .state.isInProgress) {
                                return;
                              }
                              selectActiveProxyMutation.setFuture(
                                notifier.changeProxy(group.tag, proxy.tag),
                              );
                            },
                          );
                        },
                        itemCount: group.items.length,
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.only(top: 8, bottom: 86, left: 8, right: 8),
                    sliver: SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: (width / 300).floor().clamp(1, 4),
                        mainAxisExtent: 84,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        final proxy = group.items[index];
                        return ProxyTile(
                          proxy,
                          selected: group.selected == proxy.tag,
                          onSelect: () async {
                            if (selectActiveProxyMutation.state.isInProgress) {
                              return;
                            }
                            selectActiveProxyMutation.setFuture(
                              notifier.changeProxy(
                                group.tag,
                                proxy.tag,
                              ),
                            );
                          },
                        );
                      },
                      itemCount: group.items.length,
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6),
                  const Color(0xFF2563EB),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: FloatingActionButton(
              onPressed: () async => notifier.urlTest(group.tag),
              tooltip: t.proxies.delayTestTooltip,
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: const Icon(
                FluentIcons.flash_24_filled,
                color: Colors.white,
              ),
            ),
          ),
        );

      case AsyncError(:final error):
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              appBar,
              SliverErrorBodyPlaceholder(
                t.presentShortError(error),
                icon: FluentIcons.plug_disconnected_24_regular,
              ),
            ],
          ),
        );

      case AsyncLoading():
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              appBar,
              const SliverLoadingBodyPlaceholder(),
            ],
          ),
        );

      // TODO: remove
      default:
        return const Scaffold();
    }
  }
}
