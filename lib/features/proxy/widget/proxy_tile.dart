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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF1E3A8A).withOpacity(0.6),
                        const Color(0xFF1E40AF).withOpacity(0.4),
                      ]
                    : [
                        const Color(0xFF3B82F6).withOpacity(0.15),
                        const Color(0xFF60A5FA).withOpacity(0.1),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: selected
            ? null
            : (isDark ? Colors.grey[850] : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? const Color(0xFF3B82F6)
              : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onSelect,
          onLongPress: () async {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 选中指示器
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: selected
                        ? LinearGradient(
                            colors: [
                              const Color(0xFF3B82F6),
                              const Color(0xFF60A5FA),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : null,
                    color: selected ? null : Colors.transparent,
                  ),
                ),
                const SizedBox(width: 12),
                // 节点信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        proxy.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: FontFamily.emoji,
                          fontSize: 15,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected
                              ? (isDark ? Colors.white : Colors.black87)
                              : (isDark ? Colors.grey[300] : Colors.grey[800]),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        proxy.type.label,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // 延迟显示
                if (proxy.urlTestDelay != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: delayGradientColors(context, proxy.urlTestDelay),
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: delayColor(context, proxy.urlTestDelay).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          proxy.urlTestDelay > 65000 ? "×" : proxy.urlTestDelay.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (proxy.urlTestDelay <= 65000) ...[
                          const SizedBox(width: 2),
                          const Text(
                            'ms',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color delayColor(BuildContext context, int delay) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return switch (delay) {
        < 100 => const Color(0xFF10B981),
        < 300 => const Color(0xFF22C55E),
        < 800 => const Color(0xFFFBBF24),
        < 1500 => const Color(0xFFF59E0B),
        _ => const Color(0xFFEF4444)
      };
    }
    return switch (delay) {
      < 100 => const Color(0xFF059669),
      < 300 => const Color(0xFF16A34A),
      < 800 => const Color(0xFFF59E0B),
      < 1500 => const Color(0xFFEA580C),
      _ => const Color(0xFFDC2626)
    };
  }

  List<Color> delayGradientColors(BuildContext context, int delay) {
    final baseColor = delayColor(context, delay);
    return [
      baseColor,
      Color.lerp(baseColor, Colors.black, 0.2)!,
    ];
  }
}
