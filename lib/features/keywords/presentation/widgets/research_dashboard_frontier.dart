import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../domain/entities/research_dashboard_summary.dart';
import 'chart_axis_utils.dart';

/// #27 Research Frontier Detection — bong bóng keyword: trục X = năm trung bình
/// (càng phải = càng mới), trục Y = số bài (khối lượng), cỡ = tổng trích dẫn.
/// Keyword ở góc phải-trên = chủ đề mới nổi & đang sôi động.
class ResearchDashboardFrontier extends StatelessWidget {
  final List<KeywordFrontierPoint> keywords;

  const ResearchDashboardFrontier({super.key, required this.keywords});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final pts = keywords.where((k) => k.papers > 0).toList();
    if (pts.length < 4) return const SizedBox.shrink();

    final minYear = pts.map((k) => k.meanYear).reduce(math.min);
    final maxYear = pts.map((k) => k.meanYear).reduce(math.max);
    final minYearInt = minYear.floor();
    final yearStep = yearAxisStep((maxYear - minYear).ceil());
    final maxPapers = pts.map((k) => k.papers).fold<int>(1, math.max);
    final maxCited = pts.map((k) => k.citations).fold<int>(1, math.max);

    final spots = <ScatterSpot>[];
    for (final k in pts) {
      final radius = (5 + (k.citations / maxCited) * 16).clamp(5.0, 22.0);
      spots.add(
        ScatterSpot(
          k.meanYear,
          k.papers.toDouble(),
          dotPainter: FlDotCirclePainter(
            radius: radius,
            color: AppColors.secondary.withValues(alpha: 0.55),
            strokeColor: cs.surface,
            strokeWidth: 1.2,
          ),
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
                Icon(Icons.explore_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Research frontier',
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Keyword recency × volume · ${pts.length} keywords',
              style: tt.bodySmall
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 220,
              child: ScatterChart(
                ScatterChartData(
                  scatterSpots: spots,
                  minX: minYear - 0.6,
                  maxX: maxYear + 0.6,
                  minY: 0,
                  maxY: maxPapers * 1.2,
                  scatterTouchData: ScatterTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: ScatterTouchTooltipData(
                      getTooltipColor: (_) => cs.inverseSurface,
                      getTooltipItems: (spot) {
                        final idx = spots.indexWhere(
                            (s) => s.x == spot.x && s.y == spot.y);
                        if (idx < 0) return null;
                        final k = pts[idx];
                        return ScatterTooltipItem(
                          k.keyword,
                          textStyle: TextStyle(
                            color: cs.onInverseSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          children: [
                            TextSpan(
                              text: '\n~${k.meanYear.round()} · '
                                  '${k.papers} papers · '
                                  '${NumberFormatter.compact(k.citations)} cit.',
                              style: TextStyle(
                                color:
                                    cs.onInverseSurface.withValues(alpha: 0.85),
                                fontWeight: FontWeight.normal,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      axisNameWidget: Text('Papers',
                          style: TextStyle(
                              fontSize: 9,
                              color: cs.onSurface.withValues(alpha: 0.5))),
                      axisNameSize: 14,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
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
                      axisNameWidget: Text('Mean publication year (newer →)',
                          style: TextStyle(
                              fontSize: 9,
                              color: cs.onSurface.withValues(alpha: 0.5))),
                      axisNameSize: 16,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        interval: yearStep.toDouble(),
                        getTitlesWidget: (v, _) => yearAxisLabel(
                          v,
                          minYearInt,
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
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: cs.outlineVariant, strokeWidth: 0.5),
                    getDrawingVerticalLine: (_) =>
                        FlLine(color: cs.outlineVariant, strokeWidth: 0.5),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, size: 8, color: AppColors.secondary),
                const SizedBox(width: 4),
                Icon(Icons.circle, size: 14, color: AppColors.secondary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Bigger = more cited · right = newer topics',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
