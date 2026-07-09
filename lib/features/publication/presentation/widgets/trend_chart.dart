import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../domain/entities/trend_point.dart';

/// Biểu đồ đường số bài báo theo năm (4.3 — Publication Trend Analysis).
///
/// Hiển thị tối đa [maxYears] năm gần nhất để chart dễ đọc trên mobile.
class TrendChart extends StatelessWidget {
  final List<TrendPoint> trend;
  final int maxYears;

  /// Tiêu đề + đơn vị (để tái dùng cho Publication trend / Citation trend...).
  final String title;
  final String unit;

  const TrendChart({
    super.key,
    required this.trend,
    this.maxYears = 12,
    this.title = 'Publication trend',
    this.unit = 'papers',
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (trend.length < 2) return const SizedBox.shrink();

    // Lấy [maxYears] năm gần nhất (trend đã sort tăng dần theo năm).
    final points = trend.length > maxYears
        ? trend.sublist(trend.length - maxYears)
        : trend;

    final maxCount =
        points.map((p) => p.count).reduce((a, b) => a > b ? a : b);
    final total = points.fold<int>(0, (s, p) => s + p.count);

    // Xu hướng: so sánh nửa cuối với nửa đầu để gắn nhãn tăng/giảm.
    final mid = points.length ~/ 2;
    final firstHalf = points.take(mid).fold<int>(0, (s, p) => s + p.count);
    final lastHalf = points.skip(mid).fold<int>(0, (s, p) => s + p.count);
    final rising = lastHalf >= firstHalf;
    final trendColor = rising ? AppColors.success : AppColors.error;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, size: 18, color: cs.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        rising ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: trendColor,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        rising ? 'Rising' : 'Declining',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: trendColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Total ${NumberFormatter.compact(total)} $unit '
              '· ${points.first.year}–${points.last.year}',
              style: tt.bodySmall
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (points.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxCount * 1.25,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => cs.inverseSurface,
                      getTooltipItems: (spots) => spots.map((s) {
                        final p = points[s.x.toInt()];
                        return LineTooltipItem(
                          '${p.year}\n',
                          TextStyle(
                            color: cs.onInverseSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          children: [
                            TextSpan(
                              text: '${NumberFormatter.compact(p.count)} $unit',
                              style: TextStyle(
                                color: cs.onInverseSurface.withValues(alpha: 0.8),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= points.length) {
                            return const SizedBox.shrink();
                          }
                          final last = points.length - 1;
                          final step = points.length > 8 ? 2 : 1;
                          final showByStep = i % step == 0 && i != last - 1;
                          if (i != last && !showByStep) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "'${points[i].year % 100}",
                              style: tt.labelSmall?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.5),
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxCount * 1.25 / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: cs.outlineVariant.withValues(alpha: 0.4),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < points.length; i++)
                          FlSpot(i.toDouble(), points[i].count.toDouble()),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: trendColor,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, _, _) =>
                            FlDotCirclePainter(
                          radius: 3,
                          color: trendColor,
                          strokeWidth: 1.5,
                          strokeColor: cs.surface,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            trendColor.withValues(alpha: 0.2),
                            trendColor.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
