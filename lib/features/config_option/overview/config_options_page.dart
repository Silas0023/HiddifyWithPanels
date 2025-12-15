import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/optional_range.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/notification/in_app_notification_controller.dart';
import 'package:hiddify/features/common/confirmation_dialogs.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/notifier/config_option_notifier.dart';
import 'package:hiddify/features/config_option/widget/preference_tile.dart';
import 'package:hiddify/features/settings/widgets/settings_input_dialog.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:humanizer/humanizer.dart';

enum ConfigOptionSection {
  fragment;

  static final _fragmentKey = GlobalKey(debugLabel: "fragment-section-key");

  GlobalKey get key => switch (this) {
        ConfigOptionSection.fragment => _fragmentKey,
      };
}

class ConfigOptionsPage extends HookConsumerWidget {
  ConfigOptionsPage({super.key, String? section}) : section = section != null ? ConfigOptionSection.values.byName(section) : null;

  final ConfigOptionSection? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final scrollController = useScrollController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    useMemoized(
      () {
        if (section != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) {
              final box = section!.key.currentContext?.findRenderObject() as RenderBox?;
              final offset = box?.localToGlobal(Offset.zero);
              if (offset == null) return;
              final height = scrollController.offset + offset.dy - MediaQueryData.fromView(View.of(context)).padding.top - kToolbarHeight;
              scrollController.animateTo(
                height,
                duration: const Duration(milliseconds: 500),
                curve: Curves.decelerate,
              );
            },
          );
        }
      },
    );

    String experimental(String txt) {
      return "$txt (${t.settings.experimental})";
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F7),
      body: SafeArea(
        child: Column(
          children: [
            // 自定义顶部栏
            _buildHeader(context, ref, t, isDark),
            // 内容区域
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // 提示卡片
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withAlpha(50),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            FluentIcons.warning_24_filled,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t.settings.experimentalMsg,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 路由设置
                    _buildSectionCard(
                      context: context,
                      isDark: isDark,
                      title: t.config.section.route,
                      icon: FluentIcons.navigation_24_filled,
                      iconColor: const Color(0xFF0EA5E9),
                      children: [
                        ChoicePreferenceWidget(
                          selected: ref.watch(ConfigOptions.region),
                          preferences: ref.watch(ConfigOptions.region.notifier),
                          choices: Region.values,
                          title: t.settings.general.region,
                          presentChoice: (value) => value.present(t),
                          onChanged: (val) => ref.watch(ConfigOptions.directDnsAddress.notifier).reset(),
                        ),
                        SwitchListTile(
                          title: Text(experimental(t.config.blockAds)),
                          value: ref.watch(ConfigOptions.blockAds),
                          onChanged: ref.watch(ConfigOptions.blockAds.notifier).update,
                        ),
                        SwitchListTile(
                          title: Text(experimental(t.config.bypassLan)),
                          value: ref.watch(ConfigOptions.bypassLan),
                          onChanged: ref.watch(ConfigOptions.bypassLan.notifier).update,
                        ),
                        SwitchListTile(
                          title: Text(t.config.resolveDestination),
                          value: ref.watch(ConfigOptions.resolveDestination),
                          onChanged: ref.watch(ConfigOptions.resolveDestination.notifier).update,
                        ),
                        ChoicePreferenceWidget(
                          selected: ref.watch(ConfigOptions.ipv6Mode),
                          preferences: ref.watch(ConfigOptions.ipv6Mode.notifier),
                          choices: IPv6Mode.values,
                          title: t.config.ipv6Mode,
                          presentChoice: (value) => value.present(t),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // DNS设置
                    _buildSectionCard(
                      context: context,
                      isDark: isDark,
                      title: t.config.section.dns,
                      icon: FluentIcons.server_24_filled,
                      iconColor: const Color(0xFF10B981),
                      children: [
                        ValuePreferenceWidget(
                          value: ref.watch(ConfigOptions.remoteDnsAddress),
                          preferences: ref.watch(ConfigOptions.remoteDnsAddress.notifier),
                          title: t.config.remoteDnsAddress,
                        ),
                        ChoicePreferenceWidget(
                          selected: ref.watch(ConfigOptions.remoteDnsDomainStrategy),
                          preferences: ref.watch(ConfigOptions.remoteDnsDomainStrategy.notifier),
                          choices: DomainStrategy.values,
                          title: t.config.remoteDnsDomainStrategy,
                          presentChoice: (value) => value.displayName,
                        ),
                        ValuePreferenceWidget(
                          value: ref.watch(ConfigOptions.directDnsAddress),
                          preferences: ref.watch(ConfigOptions.directDnsAddress.notifier),
                          title: t.config.directDnsAddress,
                        ),
                        ChoicePreferenceWidget(
                          selected: ref.watch(ConfigOptions.directDnsDomainStrategy),
                          preferences: ref.watch(ConfigOptions.directDnsDomainStrategy.notifier),
                          choices: DomainStrategy.values,
                          title: t.config.directDnsDomainStrategy,
                          presentChoice: (value) => value.displayName,
                        ),
                        SwitchListTile(
                          title: Text(t.config.enableDnsRouting),
                          value: ref.watch(ConfigOptions.enableDnsRouting),
                          onChanged: ref.watch(ConfigOptions.enableDnsRouting.notifier).update,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 入站设置
                    _buildSectionCard(
                      context: context,
                      isDark: isDark,
                      title: t.config.section.inbound,
                      icon: FluentIcons.plug_disconnected_24_filled,
                      iconColor: const Color(0xFF8B5CF6),
                      children: [
                        SwitchListTile(
                          title: Text(t.config.strictRoute),
                          value: ref.watch(ConfigOptions.strictRoute),
                          onChanged: ref.watch(ConfigOptions.strictRoute.notifier).update,
                        ),
                        ChoicePreferenceWidget(
                          selected: ref.watch(ConfigOptions.tunImplementation),
                          preferences: ref.watch(ConfigOptions.tunImplementation.notifier),
                          choices: TunImplementation.values,
                          title: t.config.tunImplementation,
                          presentChoice: (value) => value.name,
                        ),
                        ValuePreferenceWidget(
                          value: ref.watch(ConfigOptions.mixedPort),
                          preferences: ref.watch(ConfigOptions.mixedPort.notifier),
                          title: t.config.mixedPort,
                          inputToValue: int.tryParse,
                          digitsOnly: true,
                          validateInput: isPort,
                        ),
                        ValuePreferenceWidget(
                          value: ref.watch(ConfigOptions.tproxyPort),
                          preferences: ref.watch(ConfigOptions.tproxyPort.notifier),
                          title: t.config.tproxyPort,
                          inputToValue: int.tryParse,
                          digitsOnly: true,
                          validateInput: isPort,
                        ),
                        ValuePreferenceWidget(
                          value: ref.watch(ConfigOptions.localDnsPort),
                          preferences: ref.watch(ConfigOptions.localDnsPort.notifier),
                          title: t.config.localDnsPort,
                          inputToValue: int.tryParse,
                          digitsOnly: true,
                          validateInput: isPort,
                        ),
                        SwitchListTile(
                          title: Text(
                            experimental(t.config.allowConnectionFromLan),
                          ),
                          value: ref.watch(ConfigOptions.allowConnectionFromLan),
                          onChanged: ref.read(ConfigOptions.allowConnectionFromLan.notifier).update,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // TLS技巧设置
                    _buildSectionCard(
                      context: context,
                      isDark: isDark,
                      title: experimental(t.config.section.tlsTricks),
                      icon: FluentIcons.shield_keyhole_24_filled,
                      iconColor: const Color(0xFFEF4444),
                      sectionKey: ConfigOptionSection._fragmentKey,
                      children: [
                        SwitchListTile(
                          title: Text(t.config.enableTlsFragment),
                          value: ref.watch(ConfigOptions.enableTlsFragment),
                          onChanged: ref.watch(ConfigOptions.enableTlsFragment.notifier).update,
                        ),
                        ValuePreferenceWidget(
                          value: ref.watch(ConfigOptions.tlsFragmentSize),
                          preferences: ref.watch(ConfigOptions.tlsFragmentSize.notifier),
                          title: t.config.tlsFragmentSize,
                          inputToValue: OptionalRange.tryParse,
                          presentValue: (value) => value.present(t),
                          formatInputValue: (value) => value.format(),
                        ),
                        ValuePreferenceWidget(
                          value: ref.watch(ConfigOptions.tlsFragmentSleep),
                          preferences: ref.watch(ConfigOptions.tlsFragmentSleep.notifier),
                          title: t.config.tlsFragmentSleep,
                          inputToValue: OptionalRange.tryParse,
                          presentValue: (value) => value.present(t),
                          formatInputValue: (value) => value.format(),
                        ),
                        SwitchListTile(
                          title: Text(t.config.enableTlsMixedSniCase),
                          value: ref.watch(ConfigOptions.enableTlsMixedSniCase),
                          onChanged: ref.watch(ConfigOptions.enableTlsMixedSniCase.notifier).update,
                        ),
                        SwitchListTile(
                          title: Text(t.config.enableTlsPadding),
                          value: ref.watch(ConfigOptions.enableTlsPadding),
                          onChanged: ref.watch(ConfigOptions.enableTlsPadding.notifier).update,
                        ),
                        ValuePreferenceWidget(
                          value: ref.watch(ConfigOptions.tlsPaddingSize),
                          preferences: ref.watch(ConfigOptions.tlsPaddingSize.notifier),
                          title: t.config.tlsPaddingSize,
                          inputToValue: OptionalRange.tryParse,
                          presentValue: (value) => value.format(),
                          formatInputValue: (value) => value.format(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 杂项设置
                    _buildSectionCard(
                      context: context,
                      isDark: isDark,
                      title: t.config.section.misc,
                      icon: FluentIcons.settings_24_filled,
                      iconColor: const Color(0xFF6366F1),
                      children: [
                        ValuePreferenceWidget(
                          value: ref.watch(ConfigOptions.connectionTestUrl),
                          preferences: ref.watch(ConfigOptions.connectionTestUrl.notifier),
                          title: t.config.connectionTestUrl,
                        ),
                        ListTile(
                          title: Text(t.config.urlTestInterval),
                          subtitle: Text(
                            ref.watch(ConfigOptions.urlTestInterval).toApproximateTime(isRelativeToNow: false),
                          ),
                          onTap: () async {
                            final urlTestInterval = await SettingsSliderDialog(
                              title: t.config.urlTestInterval,
                              initialValue: ref.watch(ConfigOptions.urlTestInterval).inMinutes.coerceIn(0, 60).toDouble(),
                              onReset: ref.read(ConfigOptions.urlTestInterval.notifier).reset,
                              min: 1,
                              max: 60,
                              divisions: 60,
                              labelGen: (value) => Duration(minutes: value.toInt()).toApproximateTime(isRelativeToNow: false),
                            ).show(context);
                            if (urlTestInterval == null) return;
                            await ref.read(ConfigOptions.urlTestInterval.notifier).update(Duration(minutes: urlTestInterval.toInt()));
                          },
                        ),
                        ValuePreferenceWidget(
                          value: ref.watch(ConfigOptions.clashApiPort),
                          preferences: ref.watch(ConfigOptions.clashApiPort.notifier),
                          title: t.config.clashApiPort,
                          validateInput: isPort,
                          digitsOnly: true,
                          inputToValue: int.tryParse,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, TranslationsEn t, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          // 返回按钮（仅移动端显示）
          if (!PlatformUtils.isDesktop) ...[
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
                child: Icon(
                  FluentIcons.arrow_left_24_regular,
                  size: 20,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          // 标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.config.pageTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '自定义高级配置选项',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // 更多选项菜单
          PopupMenuButton(
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            elevation: 8,
            shadowColor: Colors.black.withAlpha(40),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  onTap: () => ref.read(configOptionNotifierProvider.notifier).exportJsonToClipboard().then((success) {
                    if (success) {
                      ref.read(inAppNotificationControllerProvider).showSuccessToast(
                            t.general.clipboardExportSuccessMsg,
                          );
                    }
                  }),
                  child: Row(
                    children: [
                      Icon(
                        FluentIcons.clipboard_arrow_right_24_regular,
                        size: 20,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 12),
                      Text(t.settings.exportOptions),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: () => ref.read(configOptionNotifierProvider.notifier).exportJsonToClipboard(excludePrivate: false).then((success) {
                    if (success) {
                      ref.read(inAppNotificationControllerProvider).showSuccessToast(
                            t.general.clipboardExportSuccessMsg,
                          );
                    }
                  }),
                  child: Row(
                    children: [
                      Icon(
                        FluentIcons.document_copy_24_regular,
                        size: 20,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 12),
                      Text(t.settings.exportAllOptions),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: () async {
                    final shouldImport = await showConfirmationDialog(
                      context,
                      title: t.settings.importOptions,
                      message: t.settings.importOptionsMsg,
                    );
                    if (shouldImport) {
                      await ref.read(configOptionNotifierProvider.notifier).importFromClipboard();
                    }
                  },
                  child: Row(
                    children: [
                      Icon(
                        FluentIcons.arrow_download_24_regular,
                        size: 20,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 12),
                      Text(t.settings.importOptions),
                    ],
                  ),
                ),
                PopupMenuItem(
                  onTap: () async {
                    await ref.read(configOptionNotifierProvider.notifier).resetOption();
                  },
                  child: Row(
                    children: [
                      Icon(
                        FluentIcons.arrow_reset_24_regular,
                        size: 20,
                        color: Colors.red.shade400,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        t.config.resetBtn,
                        style: TextStyle(color: Colors.red.shade400),
                      ),
                    ],
                  ),
                ),
              ];
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                FluentIcons.more_vertical_24_regular,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required bool isDark,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
    Key? sectionKey,
  }) {
    return Container(
      key: sectionKey,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
          // 内容
          Theme(
            data: Theme.of(context).copyWith(
              listTileTheme: ListTileThemeData(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                titleTextStyle: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                ),
                subtitleTextStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                ),
              ),
              dividerColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}
