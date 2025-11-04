import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/common/nested_app_bar.dart';
import 'package:hiddify/features/config_option/widget/collapsible_section.dart';
import 'package:hiddify/features/settings/widgets/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsOverviewPage extends HookConsumerWidget {
  const SettingsOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          NestedAppBar(
            title: Text(t.settings.pageTitle),
          ),
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Gap(8),
                  CollapsibleSection(
                    title: t.settings.general.sectionTitle,
                    icon: FluentIcons.settings_24_filled,
                    initiallyExpanded: true,
                    children: const [
                      GeneralSettingTiles(),
                      PlatformSettingsTiles(),
                    ],
                  ),
                  const Gap(8),
                  CollapsibleSection(
                    title: t.settings.advanced.sectionTitle,
                    icon: FluentIcons.options_24_filled,
                    children: const [
                      AdvancedSettingTiles(),
                    ],
                  ),
                  const Gap(24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
