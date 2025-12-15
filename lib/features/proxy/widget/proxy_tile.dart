import 'package:flutter/material.dart';
import 'package:hiddify/features/proxy/model/proxy_entity.dart';
import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/utils/custom_loggers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ProxyTile extends HookConsumerWidget with PresLogger {
  const ProxyTile(
    this.proxy, {
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final ProxyItemEntity proxy;
  final bool selected;
  final VoidCallback onSelect;

  // 从节点名称中提取国家国旗emoji
  String _getCountryFlag(String name) {
    final nameLower = name.toLowerCase();

    // 特殊节点处理（自动选择等）- 必须在国家匹配之前
    if (nameLower.contains('自动') ||
        nameLower.contains('auto') ||
        nameLower.contains('select') ||
        nameLower.contains('best') ||
        nameLower.contains('urltest') ||
        nameLower.contains('fallback') ||
        nameLower.contains('load') ||
        nameLower.contains('balance')) {
      return '⚡'; // 闪电图标表示自动选择
    }

    // 国家名称映射到国旗emoji
    final countryFlags = {
      // 亚洲
      '香港': '🇭🇰',
      'hong kong': '🇭🇰',
      'hk': '🇭🇰',
      '台湾': '🇹🇼',
      'taiwan': '🇹🇼',
      'tw': '🇹🇼',
      '日本': '🇯🇵',
      'japan': '🇯🇵',
      'jp': '🇯🇵',
      '韩国': '🇰🇷',
      'korea': '🇰🇷',
      'kr': '🇰🇷',
      '新加坡': '🇸🇬',
      'singapore': '🇸🇬',
      'sg': '🇸🇬',
      '印度': '🇮🇳',
      'india': '🇮🇳',
      'in': '🇮🇳',
      '泰国': '🇹🇭',
      'thailand': '🇹🇭',
      'th': '🇹🇭',
      '越南': '🇻🇳',
      'vietnam': '🇻🇳',
      'vn': '🇻🇳',
      '马来西亚': '🇲🇾',
      'malaysia': '🇲🇾',
      'my': '🇲🇾',
      '印尼': '🇮🇩',
      'indonesia': '🇮🇩',
      'id': '🇮🇩',
      '菲律宾': '🇵🇭',
      'philippines': '🇵🇭',
      'ph': '🇵🇭',
      '澳门': '🇲🇴',
      'macau': '🇲🇴',
      'mo': '🇲🇴',

      // 美洲
      '美国': '🇺🇸',
      'usa': '🇺🇸',
      'us': '🇺🇸',
      'united states': '🇺🇸',
      'america': '🇺🇸',
      '加拿大': '🇨🇦',
      'canada': '🇨🇦',
      'ca': '🇨🇦',
      '巴西': '🇧🇷',
      'brazil': '🇧🇷',
      'br': '🇧🇷',
      '阿根廷': '🇦🇷',
      'argentina': '🇦🇷',
      'ar': '🇦🇷',
      '墨西哥': '🇲🇽',
      'mexico': '🇲🇽',
      'mx': '🇲🇽',
      '智利': '🇨🇱',
      'chile': '🇨🇱',
      'cl': '🇨🇱',

      // 欧洲
      '英国': '🇬🇧',
      'uk': '🇬🇧',
      'united kingdom': '🇬🇧',
      'britain': '🇬🇧',
      'gb': '🇬🇧',
      '德国': '🇩🇪',
      'germany': '🇩🇪',
      'de': '🇩🇪',
      '法国': '🇫🇷',
      'france': '🇫🇷',
      'fr': '🇫🇷',
      '荷兰': '🇳🇱',
      'netherlands': '🇳🇱',
      'nl': '🇳🇱',
      '俄罗斯': '🇷🇺',
      'russia': '🇷🇺',
      'ru': '🇷🇺',
      '意大利': '🇮🇹',
      'italy': '🇮🇹',
      'it': '🇮🇹',
      '西班牙': '🇪🇸',
      'spain': '🇪🇸',
      'es': '🇪🇸',
      '瑞士': '🇨🇭',
      'switzerland': '🇨🇭',
      'ch': '🇨🇭',
      '瑞典': '🇸🇪',
      'sweden': '🇸🇪',
      'se': '🇸🇪',
      '挪威': '🇳🇴',
      'norway': '🇳🇴',
      'no': '🇳🇴',
      '芬兰': '🇫🇮',
      'finland': '🇫🇮',
      'fi': '🇫🇮',
      '丹麦': '🇩🇰',
      'denmark': '🇩🇰',
      'dk': '🇩🇰',
      '波兰': '🇵🇱',
      'poland': '🇵🇱',
      'pl': '🇵🇱',
      '乌克兰': '🇺🇦',
      'ukraine': '🇺🇦',
      'ua': '🇺🇦',
      '土耳其': '🇹🇷',
      'turkey': '🇹🇷',
      'tr': '🇹🇷',
      '爱尔兰': '🇮🇪',
      'ireland': '🇮🇪',
      'ie': '🇮🇪',
      '奥地利': '🇦🇹',
      'austria': '🇦🇹',
      'at': '🇦🇹',
      '比利时': '🇧🇪',
      'belgium': '🇧🇪',
      'be': '🇧🇪',
      '葡萄牙': '🇵🇹',
      'portugal': '🇵🇹',
      'pt': '🇵🇹',
      '希腊': '🇬🇷',
      'greece': '🇬🇷',
      'gr': '🇬🇷',
      '捷克': '🇨🇿',
      'czech': '🇨🇿',
      'cz': '🇨🇿',
      '罗马尼亚': '🇷🇴',
      'romania': '🇷🇴',
      'ro': '🇷🇴',
      '匈牙利': '🇭🇺',
      'hungary': '🇭🇺',
      'hu': '🇭🇺',
      '保加利亚': '🇧🇬',
      'bulgaria': '🇧🇬',
      'bg': '🇧🇬',
      '卢森堡': '🇱🇺',
      'luxembourg': '🇱🇺',
      'lu': '🇱🇺',
      '冰岛': '🇮🇸',
      'iceland': '🇮🇸',
      'is': '🇮🇸',

      // 大洋洲
      '澳大利亚': '🇦🇺',
      'australia': '🇦🇺',
      'au': '🇦🇺',
      '新西兰': '🇳🇿',
      'new zealand': '🇳🇿',
      'nz': '🇳🇿',

      // 中东
      '以色列': '🇮🇱',
      'israel': '🇮🇱',
      'il': '🇮🇱',
      '阿联酋': '🇦🇪',
      'uae': '🇦🇪',
      'ae': '🇦🇪',
      'dubai': '🇦🇪',
      '迪拜': '🇦🇪',
      '沙特': '🇸🇦',
      'saudi': '🇸🇦',
      'sa': '🇸🇦',

      // 非洲
      '南非': '🇿🇦',
      'south africa': '🇿🇦',
      'za': '🇿🇦',
      '埃及': '🇪🇬',
      'egypt': '🇪🇬',
      'eg': '🇪🇬',
    };

    // 遍历映射查找匹配
    for (final entry in countryFlags.entries) {
      if (nameLower.contains(entry.key)) {
        return entry.value;
      }
    }

    // 默认返回地球emoji
    return '🌐';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final flag = _getCountryFlag(proxy.name);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? (isDark ? const Color(0xFF0EA5E9).withAlpha(25) : const Color(0xFF0EA5E9).withAlpha(15))
            : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? const Color(0xFF0EA5E9)
              : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          width: selected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? const Color(0xFF0EA5E9).withAlpha(30)
                : Colors.black.withAlpha(isDark ? 20 : 8),
            blurRadius: selected ? 12 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onSelect,
          onLongPress: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                content: SelectionArea(child: Text(proxy.name)),
                actions: [
                  TextButton(
                    onPressed: Navigator.of(context).pop,
                    child: Text(MaterialLocalizations.of(context).closeButtonLabel),
                  ),
                ],
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // 国旗emoji
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800.withAlpha(150) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      flag,
                      style: const TextStyle(
                        fontSize: 24,
                        fontFamily: FontFamily.emoji,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // 节点信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        proxy.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: FontFamily.emoji,
                          fontSize: 15,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected
                              ? const Color(0xFF0EA5E9)
                              : (isDark ? Colors.grey.shade200 : Colors.grey.shade800),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              proxy.type.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          if (selected) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0EA5E9).withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '已选择',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0EA5E9),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // 延迟显示
                if (proxy.urlTestDelay != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getDelayColor(proxy.urlTestDelay).withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _getDelayColor(proxy.urlTestDelay).withAlpha(50),
                      ),
                    ),
                    child: Text(
                      proxy.urlTestDelay > 65000 ? '超时' : '${proxy.urlTestDelay}ms',
                      style: TextStyle(
                        color: _getDelayColor(proxy.urlTestDelay),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDelayColor(int delay) {
    if (delay > 65000) return Colors.red.shade400;
    if (delay < 100) return const Color(0xFF10B981);
    if (delay < 300) return const Color(0xFF22C55E);
    if (delay < 800) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
