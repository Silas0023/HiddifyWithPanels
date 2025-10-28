// traffic_chart_card.dart

import 'dart:math' as math;

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/xboard/models/user_info_model.dart';

class TrafficChartCard extends StatelessWidget {
  final UserInfo userInfo;
  final Translations t;

  const TrafficChartCard({
    super.key,
    required this.userInfo,
    required this.t,
  });

  String _formatBytes(double bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    final i = (math.log(bytes) / math.log(1024)).floor();
    final value = bytes / math.pow(1024, i);
    return '${value.toStringAsFixed(2)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final usedTraffic = userInfo.usedTraffic;
    final totalTraffic = userInfo.transferEnable;
    final remainingTraffic = userInfo.remainingTraffic;
    final usagePercentage = userInfo.usagePercentage;

    // 确定颜色（根据使用百分比）
    Color getUsageColor() {
      if (usagePercentage < 50) {
        return Colors.green;
      } else if (usagePercentage < 80) {
        return Colors.orange;
      } else {
        return Colors.red;
      }
    }

    final usageColor = getUsageColor();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.3),
              theme.colorScheme.secondaryContainer.withOpacity(0.2),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      FluentIcons.data_usage_24_filled,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '流量使用情况',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${usagePercentage.toStringAsFixed(1)}% 已使用',
                          style: TextStyle(
                            fontSize: 14,
                            color: usageColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 圆环图
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: TrafficCirclePainter(
                      usagePercentage: usagePercentage,
                      usageColor: usageColor,
                      backgroundColor: isDark
                          ? Colors.grey[800]!
                          : Colors.grey[200]!,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${usagePercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: usageColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '已使用',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 流量详情
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildTrafficRow(
                      icon: FluentIcons.arrow_upload_24_regular,
                      label: '上传',
                      value: _formatBytes(userInfo.u),
                      color: Colors.blue,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildTrafficRow(
                      icon: FluentIcons.arrow_download_24_regular,
                      label: '下载',
                      value: _formatBytes(userInfo.d),
                      color: Colors.green,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey[300], height: 1),
                    const SizedBox(height: 12),
                    _buildTrafficRow(
                      icon: FluentIcons.database_24_regular,
                      label: '已使用',
                      value: _formatBytes(usedTraffic),
                      color: usageColor,
                      isDark: isDark,
                      isBold: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTrafficRow(
                      icon: FluentIcons.storage_24_regular,
                      label: '剩余',
                      value: _formatBytes(remainingTraffic),
                      color: theme.colorScheme.primary,
                      isDark: isDark,
                      isBold: true,
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey[300], height: 1),
                    const SizedBox(height: 12),
                    _buildTrafficRow(
                      icon: FluentIcons.cloud_24_regular,
                      label: '总流量',
                      value: _formatBytes(totalTraffic),
                      color: Colors.purple,
                      isDark: isDark,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrafficRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// 自定义圆环图绘制器
class TrafficCirclePainter extends CustomPainter {
  final double usagePercentage;
  final Color usageColor;
  final Color backgroundColor;

  TrafficCirclePainter({
    required this.usagePercentage,
    required this.usageColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 15;
    const strokeWidth = 20.0;

    // 绘制背景圆环
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // 绘制使用进度圆环
    final usagePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          usageColor,
          usageColor.withOpacity(0.6),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * (usagePercentage / 100);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // 从顶部开始
      sweepAngle,
      false,
      usagePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
