import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/research_dashboard_summary.dart';
import 'chart_axis_utils.dart';

/// #4 Emerging Keywords — đường số bài theo năm của các keyword nổi gần đây.
class ResearchDashboardEmergingKeywords extends StatelessWidget {
  final List<KeywordSeries> series;

  const ResearchDashboardEmergingKeywords({super.key, required this.series});

  static const _palette = [
    AppColors.primary,
    AppColors.tertiary,
    AppColors.secondary,
    Color(0xFFE07A5F),
    Color(0xFF3D9970),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final valid = series.where((s) => s.points.length >= 2).toList();
    if (valid.length < 2) return const SizedBox.shrink();

    final years = valid.first.points.map((p) => p.year).toList();
    final minYear = years.first;
    final maxYear = years.last;
    final yearStep = yearAxisStep(maxYear - minYear);
    final maxCount = valid
        .expand((s) => s.points)
        .map((p) => p.count)
        .fold<int>(1, (m, v) => v > m ? v : m);

    final lines = <LineChartBarData>[];
    for (var i = 0; i < valid.length; i++) {
      final color = _palette[i % _palette.length];
      lines.add(
        LineChartBarData(
          spots: [
            for (final p in valid[i].points)
              FlSpot(p.year.toDouble(), p.count.toDouble()),
          ],
          isCurved: true,
          curveSmoothness: 0.25,
          color: color,
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
        ),
      );
    }

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
                    'Emerging keywords',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Keyword growth · $minYear–$maxYear',
              style: tt.bodySmall
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 190,
              child: LineChart(
                LineChartData(
                  minX: minYear.toDouble(),
                  maxX: maxYear.toDouble(),
                  minY: 0,
                  maxY: maxCount * 1.2,
                  lineBarsData: lines,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        getTitlesWidget: (v, _) {
                          if (v != v.roundToDouble()) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            v.toInt().toString(),
                            style: TextStyle(
                                fontSize: 9,
                                color: cs.onSurface.withValues(alpha: 0.5)),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        interval: yearStep.toDouble(),
                        getTitlesWidget: (v, _) => yearAxisLabel(
                          v,
                          minYear,
                          yearStep,
                          cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: cs.outlineVariant, strokeWidth: 0.5),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Chú giải màu → keyword.
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (var i = 0; i < valid.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _palette[i % _palette.length],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Text(
                          valid[i].keyword,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.labelSmall,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
