import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/config_option/data/config_option_repository.dart';
import 'package:hiddify/features/config_option/overview/config_options_page.dart';
import 'package:hiddify/singbox/model/singbox_config_enum.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class QuickSettingsModal extends HookConsumerWidget {
  const QuickSettingsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMode = ref.watch(ConfigOptions.serviceMode);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部拖拽条
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          // 标题
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  FluentIcons.options_24_filled,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '服务模式',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 服务模式选择
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252525) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(6),
            child: Row(
              children: ServiceMode.choices.map((mode) {
                final isSelected = currentMode == mode;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => ref.read(ConfigOptions.serviceMode.notifier).update(mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF0EA5E9) : const Color(0xFF0EA5E9))
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0EA5E9).withAlpha(40),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _getModeIcon(mode),
                            size: 22,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            mode.presentShort(t),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // TLS分片开关
          _buildSwitchTile(
            context: context,
            isDark: isDark,
            icon: FluentIcons.shield_keyhole_24_filled,
            iconColor: const Color(0xFF8B5CF6),
            title: t.config.enableTlsFragment,
            subtitle: '优化连接稳定性',
            value: ref.watch(ConfigOptions.enableTlsFragment),
            onChanged: ref.watch(ConfigOptions.enableTlsFragment.notifier).update,
            onLongPress: () {
              Navigator.pop(context);
              ConfigOptionsRoute(section: ConfigOptionSection.fragment.name).go(context);
            },
          ),
          const SizedBox(height: 12),
          // 更多设置
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              const ConfigOptionsRoute().go(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      FluentIcons.settings_24_filled,
                      color: Color(0xFF6366F1),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.config.allOptions,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  Icon(
                    FluentIcons.chevron_right_24_regular,
                    size: 20,
                    color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getModeIcon(ServiceMode mode) {
    switch (mode) {
      case ServiceMode.tun:
        return FluentIcons.shield_24_filled;
      case ServiceMode.systemProxy:
        return FluentIcons.globe_24_filled;
      case ServiceMode.tunService:
        return FluentIcons.server_24_filled;
      default:
        return FluentIcons.options_24_filled;
    }
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey.shade200 : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF0EA5E9),
                activeTrackColor: const Color(0xFF0EA5E9).withAlpha(50),
                inactiveThumbColor: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                inactiveTrackColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
