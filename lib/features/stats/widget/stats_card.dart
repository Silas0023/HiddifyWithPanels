import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/widget/spaced_list_widget.dart';

typedef PresentableStat = ({Widget label, Widget data, String? semanticLabel});

class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    this.title,
    this.titleStyle,
    this.padding = const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
    this.labelStyle,
    this.dataStyle,
    required this.stats,
  });

  final String? title;
  final TextStyle? titleStyle;
  final EdgeInsets padding;
  final TextStyle? labelStyle;
  final TextStyle? dataStyle;
  final List<PresentableStat> stats;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final effectiveTitleStyle =
        titleStyle ?? Theme.of(context).textTheme.bodySmall?.copyWith(
          color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        );
    final effectiveLabelStyle = labelStyle ??
        Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white.withOpacity(0.7) : Colors.black54,
            );
    final effectiveDataStyle = dataStyle ??
        Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withOpacity(0.95) : Colors.black87,
            );

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E2936).withOpacity(0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2D3E50).withOpacity(0.4)
              : Colors.black.withOpacity(0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: isDark ? 8 : 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding.copyWith(
          left: padding.left + 4,
          right: padding.right + 4,
          top: padding.top + 4,
          bottom: padding.bottom + 4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: effectiveTitleStyle,
              ),
              const Gap(6),
            ],
            ...stats
                .map(
                  (stat) {
                    Widget label = IconTheme.merge(
                      data: IconThemeData(
                        size: 15,
                        color: isDark ? Colors.white.withOpacity(0.7) : Colors.black54,
                      ),
                      child: DefaultTextStyle(
                        style: effectiveLabelStyle!,
                        overflow: TextOverflow.ellipsis,
                        child: stat.label,
                      ),
                    );
                    if (stat.semanticLabel != null) {
                      label = Tooltip(
                        message: stat.semanticLabel,
                        verticalOffset: 8,
                        child: label,
                      );
                    }
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        label,
                        const Gap(4),
                        DefaultTextStyle(
                          style: effectiveDataStyle!,
                          overflow: TextOverflow.ellipsis,
                          child: Flexible(child: stat.data),
                        ),
                      ],
                    );
                  },
                )
                .toList()
                .spaceBy(height: 4),
          ],
        ),
      ),
    );
  }
}
