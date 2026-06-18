import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../statistics_notifier.dart';

/// 月度趋势折线图 — 最近 12 个月记录数变化
class MonthlyTrendChart extends StatelessWidget {
  final List<MonthCount> monthlyTrend;

  const MonthlyTrendChart({super.key, required this.monthlyTrend});

  @override
  Widget build(BuildContext context) {
    final scheme = ShadTheme.of(context).colorScheme;
    final textTheme = ShadTheme.of(context).textTheme;

    if (monthlyTrend.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxY = monthlyTrend
            .fold<int>(0, (max, m) => m.count > max ? m.count : max)
            .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('月度趋势', style: textTheme.h4),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 0 ? (maxY / 3).ceilToDouble() : 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: scheme.border,
                  strokeWidth: 0.5,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      if (value == meta.max || value == meta.min) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: 2,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= monthlyTrend.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        monthlyTrend[index].label,
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(monthlyTrend.length,
                      (i) => FlSpot(i.toDouble(), monthlyTrend[i].count.toDouble())),
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: scheme.primary,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: scheme.primary,
                      strokeWidth: 1.5,
                      strokeColor: scheme.background,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: scheme.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
              minX: 0,
              maxX: (monthlyTrend.length - 1).toDouble(),
              minY: 0,
              maxY: maxY > 0 ? maxY * 1.15 : 5,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots.map((s) {
                    final index = s.x.toInt();
                    final label = index < monthlyTrend.length
                        ? monthlyTrend[index].label
                        : '';
                    return LineTooltipItem(
                      '$label: ${s.y.toInt()}篇',
                      TextStyle(
                        color: scheme.primaryForeground,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
