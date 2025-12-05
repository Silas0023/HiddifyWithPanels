import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/router/routes.dart';
import 'package:hiddify/features/customer_support/intercom_service.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profiles_update_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ActionButtonsRow extends ConsumerStatefulWidget {
  const ActionButtonsRow({super.key});

  @override
  ConsumerState<ActionButtonsRow> createState() => _ActionButtonsRowState();
}

class _ActionButtonsRowState extends ConsumerState<ActionButtonsRow> {
  bool _isUpdating = false;

  Future<void> _handleUpdate() async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      // 获取当前激活的profile
      final activeProfile = await ref.read(activeProfileProvider.future);

      if (activeProfile == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('没有激活的配置文件'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 触发profile更新
      await ref.read(foregroundProfilesUpdateNotifierProvider.notifier).trigger();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('配置更新成功'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('配置更新失败: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Widget _buildButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback? onTap,
    required bool isDark,
    bool isLoading = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [const Color(0xFF1E3A5F), const Color(0xFF0D2847)]
                    : [const Color(0xFFFFFFFF), const Color(0xFFF8FAFC)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 图标容器
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[0].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: isLoading
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      : Icon(
                          icon,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
                const SizedBox(height: 12),
                // 标题
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // 副标题
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 客服支持按钮
          _buildButton(
            title: '在线客服',
            subtitle: '早9-晚10点',
            icon: FluentIcons.chat_help_24_filled,
            gradientColors: [
              const Color(0xFF0EA5E9).withOpacity(0.8),
              const Color(0xFF0284C7).withOpacity(0.8),
            ],
            onTap: () => IntercomService.displayMessenger(),
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          // 更新配置按钮
          _buildButton(
            title: '更新配置',
            subtitle: _isUpdating ? '更新中...' : '获取最新',
            icon: FluentIcons.arrow_sync_24_filled,
            gradientColors: [
              const Color(0xFF10B981).withOpacity(0.8),
              const Color(0xFF059669).withOpacity(0.8),
            ],
            onTap: _isUpdating ? null : _handleUpdate,
            isDark: isDark,
            isLoading: _isUpdating,
          ),
        ],
      ),
    );
  }
}
